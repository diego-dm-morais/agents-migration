---
name: doc-writing
description: "Non-interactive writing workflow for the doc-writer role. Use when drafting or refreshing a unit doc from the implemented code and the unit artifacts. Three stages with no questions to the user: context gathering, section-by-section drafting with surgical edits, and a reader self-test. Every fact is cited."
user-invocable: false
---

# doc-writing

Writing process for the doc-writer role. It shapes how a unit doc is gathered, drafted and tested. It never changes what the doc may say: `migration-conduct` and the doc-writer prompt win over this skill.

## Fixed meta-context

These replace the questions a user would be asked.

- **Reader:** anyone, including a person who has never read the source or the target code (product, operations, a new developer).
- **Goal:** after reading, the reader knows what the unit does, what goes in, what comes out, what can fail and why, and which rules apply.
- **Language:** `doc_language` in `docs/migration/MIGRATION.md`. Identifiers, literals, paths, `path:line`, ids, frontmatter keys, SQL, enum values, protocol names, and error or validation messages stay as written (`migration-conduct` section 9).
- **Structure:** the headings the doc-writer prompt fixes. If it fixes none, cover the parity dimensions of `migration-conduct` section 1 (inputs, outputs, errors, side effects) and the rules (`BR-`, `FR-`, `TS-`), then end with the `## Sources` table of `templates.md`.

## Stage 1: Context gathering (no questions)

Goal: find what the reader needs, using the sources only.

1. Read `docs/migration/MIGRATION.md`: `doc_root`, `doc_language`, `source_root`, `source_sha`, `target_root`, `target_language`.
2. Read the implemented code first. The `files:` lines of `docs/migration/<unit>/tasks.md` name what was built (paths relative to `target_root`). Read those files with ranged Read. The implemented code is the only source of behavior.
3. Read the unit artifacts for context only: `extraction.md` (`BR-` rules with their citations), `spec.md` (`FR-`, `TS-`, `NG-`, `AG-`), `plan.md` (`ID-`), `review.md` (open `RV-`). Label every fact taken from them as context.
4. Write 5-10 questions a real reader would ask. Example shapes: what the unit does; what happens when an input is missing; what an error looks like; what a term means.
5. Answer each question from the code, with `path:line`. Answer from an artifact only with its id, labeled as context. Never answer from memory.
6. A question with no answer in the sources is a gap. Record it, with what you checked.
7. List the terms that need a plain definition.

Exit: every question has an answer or a recorded gap.

## Stage 2: Drafting (section by section)

Goal: build the doc one section at a time, with plain language and citations.

1. If the doc does not exist, write the skeleton in one Write call: the frontmatter and the Sources table of `templates.md`, then each section heading in the order of the sections of `.claude/agents/doc-writer.md`, each followed by `[PENDING]`, with `status: draft`. The skeleton comes first, so an interrupted run resumes from the file. If the doc exists, Read it and edit it in place with Edit: keep each statement that still holds and every id, delete the rest. For each section it rewrites, first set that section back to `[PENDING]` with Edit. Never overwrite it with Write (`.claude/agents/doc-writer.md` lines 27 and 58).
2. Order of work: the section with the most open questions first, then inputs and outputs, then errors, then the summary last, written from the finished sections.
3. For each section:
   - gather its facts from stage 1 and the code;
   - list 5-20 candidate points, each with its citation;
   - keep what the reader needs; drop duplicates and points that do not change the reader's understanding;
   - write two to four plain sentences first, then the tables, every row cited;
   - replace `[PENDING]` with the text using Edit. Never rewrite the whole file.
4. After three passes with no relevant change, stop cutting. A cut never removes a fact, a number, a status code, an error or a rule id.
5. At about 80% of the sections, reread the whole doc: flow, repeated facts, contradictions, filler. Fix each one with Edit.
6. No `[PENDING]` may remain.

Plain-language checks, per section:
- short sentences, active voice, present tense;
- each technical term explained before its first use, or in a glossary section;
- numbers, formulas and constants copied exactly as the code writes them. Simpler words never change a number.

## Stage 3: Reader self-test

Goal: find the blind spots the author cannot see.

1. Write 5-10 questions that a reader holding only the doc would ask. Cover: what the unit does, what it needs, what it returns, what fails and why, which rules apply, what a term means.
2. Answer each question from the doc text only. Mark each answer `answered`, `ambiguous`, `assumes-unexplained` or `contradicts`.
3. Fix each mark in place with Edit: define the term; add the missing fact from the code, with its citation; remove the contradiction. A fix never adds a fact the code does not show.
4. Repeat at most two rounds. A mark still open after two rounds goes to the report, with the question and the section it came from.

This self-test is run by the agent that wrote the doc, not by an independent reader. The report says so.

## Writing standard: clear enough for a junior developer

Apply this to every doc the role writes, unit docs and toolkit docs alike. It sets how the text reads. It never changes a fact, a citation or an id.

1. **Start with the answer.** The first two sentences of each section say what the reader needs to know. Details come after.
2. **One idea per paragraph.** A paragraph with more than one idea is split.
3. **Short sentences.** Aim for up to 20 words. Active voice, present tense. Cut words that add nothing: "basicamente", "na verdade", "é importante notar que".
4. **Define before use.** Each technical term is explained the first time it appears, in plain words, with an example taken from the code or a test when one exists. Otherwise the term goes in the Glossary.
5. **Say why, in one sentence.** Each rule, limit or error gets one sentence on why it exists, when the code or a cited source shows the reason. If no reason is in the sources, say so; never invent one.
6. **Use the same word for the same thing.** Pick one term per concept and keep it through the doc. A reader who sees two names thinks there are two things.
7. **Tables for lists of facts, prose for reasoning.** Each table row cites its source. A table never holds a paragraph.
8. **Concrete over abstract.** Show the shape of an input or output with the types the code declares. Examples come only from a test or fixture read in this run (`.claude/agents/doc-writer.md`, rule on examples).
9. **Steps are numbered.** A process is a numbered list, one action per step, in the order the code runs it.
10. **No filler, no hype.** Drop intros like "Este documento apresenta" and closings like "Espero que ajude". The doc states facts and nothing more.
11. **Test by reading aloud.** A sentence a junior would need to read twice is rewritten.

What never gets cut for clarity: citations, numbers, status codes, error messages, rule ids, and the `known-issue` and `deviation` markers.

## Rules that never change

- The implemented code is the only source of behavior. Specs, extraction, plan and review are context and stay labeled as context.
- Every claim is cited. Target code: `path:line` relative to `target_root`, with no `@sha7` (`.claude/agents/doc-writer.md`). Library code: the dependency source file and line at the version the lockfile pins, or the official URL for a runtime fact. Open each cited line in this run before citing it (`migration-conduct` section 2; `.claude/agents/doc-writer.md` line 53).
- A rule the code does not show is not written. It is a gap, in the doc and in the report.
- Bugs are described as the code behaves, neutrally, and marked `known-issue: <reference>`. The doc gives no recommendation.
- Plain language never removes a citation, a number, a status code or a rule id.
- Never copy a secret value. Write `<redacted>` and cite where the value is.
- Hashes: each `cksum` in the Sources table comes from `check.sh hash <file>`, and `scope_hash` comes from `check.sh scope <unit>`, run as `templates.md` shows. Never compute them by hand.
- Set `status: ok` once the doc-stage criteria of `stages.md` hold: the Sources table and `scope_hash` match the check.sh values. Then run `check.sh status <unit>`. If the doc line is not `OK`, set `status` back to `draft`. Check.sh shows `OK` only for `status: ok` (check.sh lines 318-319).
- Never ask the user. A question the sources do not answer is a gap in the doc and in the report. Stop with `NEEDS: user: <question, quoted>, verified: <paths and lines you read>` only when the doc cannot be finished without a decision that the implemented code, the dependency source at the pinned version and the official documentation do not settle, checked in that order (`migration-conduct` section 0, rules 6 to 9). No other owner is allowed (`.claude/agents/doc-writer.md` line 65).

## Final report

Use the final message contract of `migration-conduct` section 12. Put the open gaps and the self-test marks still open in `Open:`, at most three lines. The full list is in the doc.
