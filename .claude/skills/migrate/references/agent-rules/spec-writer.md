# spec-writer: rules, UI units and architecture mode

Read by `spec-writer` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- Acceptance for a UI requirement is an observable state after an event: the event (user action or lifecycle trigger), then the visible text or state (for example `Text "Saved"` shown, button disabled, error message `<source literal>` shown), or the navigation target (route and params). Never write it as input to output.
- Fidelity is behavioral. Layout is recorded as a screenshot reference (path in the source or the design file, cited) or as a design token (name and value, cited). A pixel-level requirement (exact spacing, exact color, animation timing) is a `PEND-` with `blocking: no` and the default `behavioral parity, layout by reference`; it is never an invented `FR-`.
- Each UI state from the extraction (loading, empty, error, permission denied) gets its own `FR-` with its own acceptance.
- Strings: acceptance uses the source literal or i18n key exactly as the source has it.

## Rules

- Every requirement traces to a rule, a citation, or a user decision. Nothing else. Each FR carries `Source: BR-...`; `check.sh` rejects an FR without it.
- Do not turn an observation into a rule the extraction does not contain. Never reinterpret a rule to make it look like a best practice.
- Before a PEND, check the extraction, the code it cites, and the dependency source at the pin. A PEND exists only when that investigation finds nothing. A question the code answers is never a PEND.
- A PEND with `blocking: no` records the default you would use. It is never a question to the user.
- A blocking PEND (`blocking: yes`, no resolution) stops the spec as BLOCKED. End with `NEEDS: user: <question, quoted>, verified: <paths and lines you checked>` for it (conduct rule 9).
- Contract choices are not spec facts. The input type, the output format, the error class and the error category are fixed only when the source code fixes them. When the source leaves one open, write a PEND, with `blocking: yes` when a caller can depend on it. Never write a grammar, a representation or a class as a requirement because you chose it.
- TS requirements come only from the conventions and `NFR-` items in MIGRATION.md and from the source's own evidence. Keep acceptance target-neutral: name the error category (value rejected, type rejected, precision exceeded) and the source message when the source has one. The concrete target class and text belong to the plan.
- Keep identifiers, literals, paths and error messages exactly as the source states them.
- Legacy fidelity (conduct rule 10): every legacy behavior and every `DEC-NNN` of the extraction becomes an FR, a TS or an NG with its citation. Never drop, soften or reinterpret a legacy decision that contradicts best practice. A question the legacy code answers is never a PEND: cite the fact instead.
- Write labels in `artifact_language`.
- Write only `docs/migration/<unit>/spec.md`.
