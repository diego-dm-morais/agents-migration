# Async and ordering (JavaScript)

Read this when a migration touches promises, async and await, promise combinators, or any code whose result depends on the order in which callbacks run. Probe outputs were run on Node.js 22.23.1 on 2026-10-29. Host queues (timers, process-level queues, I/O) are not covered here; the nodejs skill owns them.

## The job queue

- When a promise settles, every reaction registered on it becomes a job. TriggerPromiseReactions enqueues one job per reaction (ECMAScript 27.5.1.8, living draft; verify before use). Each job runs its handler when it reaches the front of the queue (NewPromiseReactionJob, 27.5.2.1; verify before use).
- Jobs run first in, first out. A job that resolves another promise adds that promise's reactions at the back.
- Synchronous code always finishes before any job runs.

## Probe: promise-only ordering

Source of the probe (`promise-order.mjs`, abridged):

```js
console.log('1 sync start');
Promise.resolve().then(() => console.log('A1')).then(() => console.log('A2'));
const outer = new Promise((resolve) => resolve(Promise.resolve()));
outer.then(() => console.log('outer (resolved with a promise)'));
const p = Promise.resolve();
p.then(() => console.log('B1')).then(() => console.log('B2')).then(() => console.log('B3'));
async function f() {
  console.log('f start (sync part of async function)');
  await null;
  console.log('f after await');
}
f();
console.log('2 sync end');
```

Output, exit code 0:

```
1 sync start
f start (sync part of async function)
2 sync end
A1
B1
f after await
A2
B2
outer (resolved with a promise)
B3
```

How to read it:

- The synchronous lines come first. The part of an async function before its first `await` runs during the call.
- Each reaction is one job. The jobs for A1, B1 and the `await` were queued in the order of the calls, so they run in that order.
- `await null` resumes as a job queued after B1, so `f after await` appears after B1.
- `outer` was resolved with a promise. That costs two extra jobs before its reaction runs, so it runs at the third job of its chain, the same depth as B3. It runs before B3 because its job was queued earlier in that round.

## Rules for migrated code

- Do not depend on which of two independent chains logs first. Make the order explicit: one chain, or one `await` after the other.
- Do not count the jobs an `await` takes as a contract. Test the observable result, not the number of ticks.
- A source that logs in one order and the target that logs in another is a parity gap, even when the final result matches. Test the order when the source output includes logs or events.

## async functions

- An `async` function runs its body synchronously until the first `await`, then returns a promise (probe: `f start` prints before `2 sync end`).
- An `await` of any value, including `null`, resumes as a job. Code after it runs after jobs queued earlier (probe: `f after await` runs after B1).
- A thrown error inside an `async` function rejects its returned promise. Callers catch it with `try` around `await`, or with `.catch`.

## Combinators

Probe results (Node.js 22.23.1):

- `Promise.all([slow, fast])` returns values in input order, not completion order: `["slow first in input","fast second in input"]` (the first element finished last).
- `Promise.all` rejects with the first rejection. MDN Promise/all gives the fail-fast example: the result is rejected as soon as one element rejects, and it logs that error.
- To keep every outcome, use `Promise.allSettled`: `[Promise.reject(new Error("x")), 5]` gives `rejected` with reason `x`, then `fulfilled` with value `5`.
- `Promise.try` is not available on Node.js 22.23.1 (probe `typeof Promise.try` is `"undefined"`). MDN marks it Baseline 2025. Use `new Promise` or an `async` function instead.

## Shared state across await

- A read, then an `await`, then a write to the same object can interleave with other jobs that touch that object. The read value may be stale when the write happens.
- Keep the read, the `await` and the write in one section that does not depend on other jobs, or copy the values before the `await` and write them back as one step.
- Guard the section with a queue inside the code when two callers can reach it at the same time. Add a library only if the repository already has one.

## Unhandled rejections

- A rejected promise that is never awaited, returned or caught is a defect of the migrated code. Make every promise either awaited, returned, or given a `.catch` in the same function.
- In a migrated unit, one error path in the source maps to one rejection in the target. Test each path with a rejected input.
