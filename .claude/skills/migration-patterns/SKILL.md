---
name: migration-patterns
description: "Trap categories a code migration must check between a source and a target language: numbers, text, time, absent values, ordering, errors, concurrency, serialization, I/O, configuration, clocks, locale. Each with the source question, the pinning test and the parity rule, plus migration shapes."
user-invocable: false
---

# Migration patterns

Use this skill to find the traps that break parity when code moves from the source language to the target language. Parity means the same accepted and rejected inputs, the same outputs, the same errors and the same observable side effects (migration-conduct section 1).

For each unit, check every category in section 1 that its entry point touches. Record each hit as a cited fact in the extraction (`Numeric and type semantics`, a `BR-` rule, or `Gaps`). Pin each hit with a test at the evidence level that migration-conduct section 3 names. For the target construct of each source construct, see `references/idiom-map.md`.

## 1. Trap categories

Each entry gives the question to ask in the source, the test that pins the behavior, and the parity rule. Start with Grep; read each hit with a ranged Read.

### Numbers
- Ask: grep arithmetic on quantities, prices and rates; rounding calls; integer division and remainder; the numeric type of each value; number parsing and casts; overflow checks.
- Pin: derived cases at zero, negative values, the smallest and largest accepted value, a tie such as x.5, and a value a binary float cannot hold exactly (L1).
- Parity: same rounding mode on ties, same scale, same accepted range, same overflow outcome. Keep the source's numeric type and scale. Exact decimal stays exact. If the source keeps a value in a binary float, the target keeps that behavior and records it as `known-issue` or `deviation` (migration-conduct sections 0.3 and 5). A change of numeric type is a decision recorded as an `ID` or a `PEND` (migration-conduct section 7).

### Text and encoding
- Ask: grep length, slicing, trimming, case folding, regex, byte conversion, charset of input and output, normalization.
- Pin: multibyte characters, combining marks, leading and trailing spaces, the empty string, and a length limit measured in the unit the source counts: bytes, code points or code units (L1).
- Parity: same length unit, same trim set, same case rules, same charset on the wire. A regex runs on the target engine with the source's inputs, because dialects differ.

### Time and time zones
- Ask: grep date parsing and formatting, zone names and offsets, durations, epoch units (seconds or milliseconds), date-only versus timestamp types, and any use of the process time zone.
- Pin: midnight, a day boundary in the source's zone, a daylight saving change, a leap day, and the same epoch value in each unit (L1; L2 for formatted output).
- Parity: same zone rules, same epoch unit, same type for date-only values, same output pattern and precision. The runtime's default zone never decides.

### Absent values
- Ask: grep null, nil, None, undefined, missing keys, empty strings, zero used as "not set", defaults, and what the serializer writes for each.
- Pin: each input form (field missing, null, empty, zero) and the output for each (L1; L2 golden).
- Parity: keep absent, null, empty and zero apart as the source does. Compare the wire form (present, omitted or null), not the language value, because languages disagree on absence.

### Equality and ordering
- Ask: grep equality operators, comparison of objects and collections, sort calls and comparators, map iteration, hash keys, query result order.
- Pin: ties, duplicates, mixed types in a comparison, and the order of output lists with equal keys (L1).
- Parity: same equality (value or identity, strict or coercing), same tie order, same key order in output. If the source defines no order, the source is silent on a technical choice: use best practice, mark it `deviation` with its reason and source (migration-conduct section 4), and do not present it as a legacy rule.

### Error model
- Ask: grep throw, raise, return codes, error types, catch and rethrow, panics, wrapping, the status and body written for each failure, and the exceptions no handler catches.
- Pin: one case per error path with its input, checking kind, status, body and message; one exception that escapes the handler (L1; L2 for bodies).
- Parity: same error kind at the boundary, same status and body, same validation messages, same check order when two errors apply. Escaped exceptions follow the source's framework behavior, bugs included.

### Concurrency
- Ask: grep threads, goroutines, async calls, locks, shared mutable state, caches, transactions, background jobs, retries, timeouts.
- Pin: the same operation run in parallel, checking the final state; a case where a timeout or retry fires (L1; L3 for a parity claim).
- Parity: same final state, same retry count, same timeout error, same lock or transaction boundary. Scheduling order is a parity point only when the source makes it observable.

### Serialization
- Ask: grep JSON, XML and binary encoders, field names and casing, tags and annotations, omit-empty rules, date and number formats, key order, escaping, content type.
- Pin: source golden output for each shape: full, minimal, null fields, empty collections, unknown input fields (L2).
- Parity: compare the parsed structure, not raw text, unless the spec requires bytes. Same field names, presence, nulls and number formats; same accept or reject for unknown input fields.

### I/O and resources
- Ask: grep file, socket and HTTP calls, queries, timeouts, pools, buffer sizes, close and release calls, logs written.
- Pin: a fake of each dependency that records calls, their order, their arguments and their failures (L1). Real dependencies only in differential runs (L3).
- Parity: same outgoing calls in the same order, same side effects, same timeouts and retries, same release order where it changes output.

### Configuration
- Ask: grep environment variables, config files, defaults, feature flags, precedence between sources, parsing of booleans, lists and durations.
- Pin: a test built from explicit values: defaults, missing keys, an invalid value (L1).
- Parity: same keys, defaults, precedence and parsing. Values read from the environment are strings in most runtimes; the source's parse rule decides the target's result.

### Randomness and clocks
- Ask: grep random sources, id generation, the current time, counters, salted hashes, seed source.
- Pin: an injected fixed source. For generated values, test the rule (format, length, range, uniqueness), not the value (L1).
- Parity: the same rule holds. A value the source draws at random is never golden-compared. Time comes from an injected clock in the target.

### Locale
- Ask: grep number and date formatting, currency symbols, collation, case conversion, language-dependent sorting, message catalogs, the runtime's default locale.
- Pin: the same inputs under two locales that format differently (decimal separator, date order), compared with the source output under its fixed locale (L2).
- Parity: the locale is an explicit input or a fixed setting, never the machine default. Formats and collation match the source's locale.

### State and lifecycle on screens
- Ask: grep component mount and unmount hooks, dispose or destroy calls, lifecycle callbacks, local state that outlives its screen, global or shared state read by a screen, initial-value code that runs on each render or each visit.
- Pin: each state transition the source allows (loading, empty, error, loaded, editing), one case per transition, and a case where the user leaves the screen during a pending action (L1; L3 for a parity claim on the visible result).
- Parity: the same state after each user event and each lifecycle event; the same initial value on first visit and on a return visit; no state kept after the screen is gone unless the source keeps it.

### Async races on screens
- Ask: grep requests started from UI events, awaited calls that update state, debounced or throttled inputs, retries, polling, subscriptions, and any code that writes state after an await.
- Pin: two requests for the same screen where the second returns first; a response that arrives after the screen is gone; a response that arrives after a newer user input (L1, with a fake that controls the order of responses).
- Parity: the same final visible value as the source in each order. Stale responses are dropped or applied exactly as the source does. A write to state after dispose or unmount is an error in most frameworks: the target skips it, and the skip must match the source's observable output (for example, no navigation after the user left).

### Navigation and back stack
- Ask: grep push, pop, replace, clear-stack and redirect calls; deep link handlers; the action that a back gesture or a back button triggers; route guards; the screen that opens after a success or failure.
- Pin: the stack depth and the top screen after each action, from a cold start and from a deep link; the back action on the first screen (L1; L3 for the visible flow).
- Parity: the same screens in the same order, the same parameters on each screen, the same result when the user goes back with unsaved input. A deep link to a screen that needs data must follow the source's fallback.

### Focus and keyboard
- Ask: grep focus requests, input field order, submit actions, keyboard types, auto-focus on open, scroll-to-field on error, shortcuts and key handlers.
- Pin: tab or next-field order for each form; the submit action with an empty and a filled form; the focus after a validation error (L1 for order; L3 for the visible focus).
- Parity: the same focus order and the same field that receives focus after an error. A key that submits in the source submits in the target; a key the source ignores stays ignored.

### Text layout and overflow
- Ask: grep fixed widths and heights, truncation, ellipsis, line limits, text that is measured or sized in code, text built from pieces, and labels placed beside icons.
- Pin: the longest value the source accepts, a value with no spaces, a value in the script the product supports (for example a multi-byte or right-to-left string), at the largest text scale the platform offers (L2 for the visible text).
- Parity: the same truncation point and the same line count for the same input, or a recorded `deviation` when a platform forces a different wrap. A label that the source truncates is not extended by the target.

### Time zones in displayed dates
- Ask: grep date formatting in views or templates, the zone used to display, relative dates ("today", "yesterday"), ranges that cross midnight, and the zone of the server versus the device.
- Pin: the same instant displayed in the source's zone, a value at midnight in that zone, and a value on a daylight saving change day (L2 for the displayed text).
- Parity: the zone is the source's fixed zone or the user's zone exactly as the source sets it, never the machine's default by accident. "Today" is computed in the zone the source uses.

### Platform differences
- Ask: grep platform checks (OS name, device form, web versus native), platform-specific files or styles, back button handling, safe-area or inset code, default fonts and default controls, permissions prompts.
- Pin: each branch of a platform check with a test for each platform the source supports; the default control or font on each platform, compared with the source's recorded output (L2 for screens).
- Parity: the same behavior on each platform the source supports. A difference the platform forces is recorded as `deviation` with the platform's documented reason and its URL, and it is never silent.

## 2. Migration shapes

Pick the shape per unit in the `Target design` section of plan.md. The parity evidence is the same in every shape.

- Strangler fig: the target replaces the source unit by unit while both systems coexist, built at the seams of the legacy system. Source: https://martinfowler.com/bliki/StranglerFigApplication.html ("Once we have seams to isolate a few components, we can start replacing them."; "building transitional architecture to allow the new and legacy system to coexist"). The router or proxy that serves the selected units, and the rollback of one unit alone, are this skill's own design and are not in that page. Use it when units are independent and each can be switched and rolled back alone.
- Branch by abstraction: put an abstraction in front of the source behavior, move callers to it, build the target implementation behind it, and switch callers over gradually. Use it when the source sits in a codebase whose callers cannot all move at once. Source: https://martinfowler.com/bliki/BranchByAbstraction.html (read in this run).
- Parallel run: the source and the target receive the same input; the source answer is returned, the target answer is compared and differences are logged. Use it when a wrong answer is costly and the target's side effects can be suppressed. Defined in this skill, not cited; a parity claim from it needs L3 evidence.

## 3. Rules

- A trap found in the source is a cited fact (`path:line @sha7`) or a gap. A trap the source does not show is not a rule.
- A trap the source keeps as a bug stays, marked `known-issue`.
- Language details for each construct are in the language skill named by MIGRATION.md (`source_language`, `target_language`), not in this skill.
