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

## 2. Migration shapes

Pick the shape per unit in the `Target design` section of plan.md. The parity evidence is the same in every shape.

- Strangler fig: the target replaces the source unit by unit while both systems coexist, built at the seams of the legacy system. Source: https://martinfowler.com/bliki/StranglerFigApplication.html ("Once we have seams to isolate a few components, we can start replacing them."; "building transitional architecture to allow the new and legacy system to coexist"). The router or proxy that serves the selected units, and the rollback of one unit alone, are this skill's own design and are not in that page. Use it when units are independent and each can be switched and rolled back alone.
- Branch by abstraction: put an abstraction in front of the source behavior, move callers to it, build the target implementation behind it, and switch callers over gradually. Use it when the source sits in a codebase whose callers cannot all move at once. Source: https://martinfowler.com/bliki/BranchByAbstraction.html (read in this run).
- Parallel run: the source and the target receive the same input; the source answer is returned, the target answer is compared and differences are logged. Use it when a wrong answer is costly and the target's side effects can be suppressed. Defined in this skill, not cited; a parity claim from it needs L3 evidence.

## 3. Rules

- A trap found in the source is a cited fact (`path:line @sha7`) or a gap. A trap the source does not show is not a rule.
- A trap the source keeps as a bug stays, marked `known-issue`.
- Language details for each construct are in the language skill named by MIGRATION.md (`source_language`, `target_language`), not in this skill.
