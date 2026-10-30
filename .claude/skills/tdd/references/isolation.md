# Isolation of external dependencies

Read this when a unit test needs a dependency, when a task creates or changes a package that talks to something outside itself, or when the gate reports a forbidden call.

## 1. Dependency table

Every external dependency is reached through an interface owned by the package that consumes it. Constructors take the interface.

| Dependency | Production code | Unit test |
|---|---|---|
| Database | The code depends on a query interface that the consumer owns, with only the methods it calls. Never a concrete connection, pool or client type in the code under test. If the generator emits a query interface, check the generated file and use it. | A double of that interface (generated for interfaces the package owns) or a hand-written fake. |
| Network client | A client built on an injected transport. | A fake transport, or an in-process test server. Never a real host. |
| Time | An injected clock. | A fixed clock. |
| Randomness | An injected random source. | A fixed source. Assert invariants (range, uniqueness), not one exact random value. |
| Configuration | A configuration value passed in. | Built in the test. Never read from the real environment. |
| Queues and cloud services | An interface owned by the consumer. | A double or a fake. |
| Any other external service | An interface owned by the consumer. | A double or a fake. No real service is started. |

## 2. Forbidden in unit tests

Any hit in a unit test file or in the package under test blocks the task until it is removed. Search the package directory for these calls before the gate. Use the target language's own names for them (from its language skill):

- a call that opens a real database connection, pool or client;
- a call that opens a real network connection, or uses a default network client;
- a read of the real clock or of the global random source in the code under test;
- a read of real environment variables, in the code under test or in the test;
- a start of a container runtime or of an external service.

## 3. Adapter tests

- Code that calls a double is covered by unit tests that set the expected calls and the rows or errors the double returns.
- These tests check the adapter's logic: arguments, error mapping, call order (for example, a session setting applied before the query), and row mapping.
- Unit tests do not execute the query text, the wire format or the protocol. The report says so for every package that talks to a database or a remote service.

## 4. Seams

- When a line can be reached only with a real resource, the seam is wrong. Move the logic behind an interface, or into a pure function, and test that.
- Never add a real resource to pass the gate.
- If the seam cannot be fixed inside the task, the task is `blocked` and reported.

## 5. Report

- For each package the task creates or changes: the unit coverage ratio from the profile, the interfaces doubled, and the adapter tests that used a double.
- A requirement that only a real resource can check is an open item in the report, never a test with a real resource.
- A plan step or a standard that asks for a real resource in unit tests is a divergence. This rule applies, and the report records it as a `deviation`, citing its source.
