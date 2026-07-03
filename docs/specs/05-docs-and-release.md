# Spec 05 — Docs & release

Phase 5 of this project's phased build-out. No feature code changes — this phase reconciles documentation with what was actually built and prepares the deliverable Enjoei receives, per the test brief's delivery section (zip + README covering technical choices and AI usage).

## Goal

Ship a deliverable that (1) documents the AI-usage transparency the brief explicitly asks for, (2) contains only documentation useful to an outside reviewer — the final technical record plus real evidence of the spec-first process, not this project's session-level AI-collaboration scaffolding — and (3) has been verified to actually build and run from a clean checkout.

## What's already done (not repeated here)

Confirmed against the current state of the repo before writing this spec, per the phase-lifecycle "Middle" step:
- `docs/ARCHITECTURE.md` reconciliation (pagination via `next_page`, `ImageURLBuilder` as pure concatenation, folder structure, UI-tests reversal) — done during Phase 3's documentation audit, not deferred here.
- `docs/PLAN.md` status table — kept current after every phase merge; Phase 4's row already reads "Merged — [#5]" as of this phase's first commit.

## Inputs

- `docs/AI_USAGE_LOG.md` — the running, per-phase log kept since Phase 3 specifically so this section wouldn't need to be reconstructed from memory.
- `docs/CONTEXT_TEST.md` §5 — the literal ask: "AI superpowers" section must cover concretely how AI was used (boilerplate? refactors? syntax lookups?) — no answer is penalized, the goal is transparency.
- The developer's own decision (this phase, revised after first reading the literal brief's evaluation criteria again — see below): **which docs actually ship.**

## Delivery scope (final decision, supersedes an earlier draft call)

What ships — tracked in git going forward, on `main`, and in the zip: `README.md`, `docs/ARCHITECTURE.md`, `docs/specs/*.md`.

What doesn't ship: `docs/CONTEXT_TEST.md`, `docs/PLAN.md`, `docs/DESIGN_GUIDE.md`, `docs/AI_USAGE_LOG.md`, `CLAUDE.md`. These are **untracked via `.gitignore`, not deleted** — they stay as local working files (the developer keeps using `PLAN.md`/`CLAUDE.md` across future sessions on this repo; they're moved aside during the zip step itself and restored after), they just stop being part of what git tracks/pushes from this commit forward. Prior commits that already contain them are not rewritten — `develop`'s history keeps them, only new changes stop being tracked.

Reasoning for the revision: the literal brief (`docs/CONTEXT_TEST.md` §2, §5) asks the README for two things — technical choices and AI usage — and states evaluation focuses on "a arquitetura escolhida, a qualidade das abstrações, a cobertura de testes e a fidelidade aos detalhes visuais... não [n]a utilização de IA." Nothing in the brief asks for process docs. On reconsideration, `docs/specs/*.md` earn a place anyway (not because the brief asks for them, but because they're real, phase-by-phase evidence of the architecture decisions and abstractions the brief says it *does* evaluate — the job posting's own shape-up/transparency framing makes this a genuine plus, not padding). `docs/PLAN.md`, `docs/DESIGN_GUIDE.md`, `docs/AI_USAGE_LOG.md`, and `CLAUDE.md` don't clear that bar: they're status tracking, a screenshot-reading narrative, a raw AI-collaboration log, and an AI working agreement respectively — genuine process artifacts, but not technical documentation an evaluator needs, and left in would dilute focus from what's actually being judged.

## Outputs

1. **`README.md` "AI usage" section**, replacing the placeholder — a real, concise account of the AI-collaboration pattern used across all 5 phases (spec-first workflow, what AI drafted vs. what required human judgment/correction, concrete examples of both), consolidated from `docs/AI_USAGE_LOG.md` rather than a generic "AI helped with the code."
2. **`.gitignore` updated** with the five excluded paths (`CLAUDE.md`, `docs/CONTEXT_TEST.md`, `docs/PLAN.md`, `docs/DESIGN_GUIDE.md`, `docs/AI_USAGE_LOG.md`), plus `git rm --cached` on each so they stop being tracked without being deleted from disk.
3. **The `develop` → `main` PR**, opened once the above is committed and the developer has manually moved the untracked docs aside and confirmed the zip contents locally.
4. **The delivery zip**, built from a fresh clone of `main` after the PR merges (a clean clone never had the untracked files' *current* versions, only whatever `develop`/`main` history had before they were untracked — irrelevant here since they're no longer part of the tree at all going forward).

## Decisions & edge cases

- **Untrack via `.gitignore`, not a delete commit**: chosen over the earlier plan (a cleanup commit that `git rm`s the files, recoverable only via `develop`'s history) because the developer wants to keep actively editing local copies of `PLAN.md`/`CLAUDE.md` across future sessions without them reappearing in `git status`/diffs or getting accidentally re-committed.
- **Dangling cross-references, flagged then fixed on the developer's call**: `docs/specs/00-04-*.md` referenced `docs/PLAN.md`, `docs/CONTEXT_TEST.md`, and `docs/DESIGN_GUIDE.md` by path in several places (e.g. "per the phase lifecycle in `docs/PLAN.md`"). Since those files are excluded from the shipped repo, a reader would otherwise hit references to files that aren't there. Initially proposed as "leave as-is" (the specs ship as process evidence, a reference to the doc that produced them is arguably still coherent); the developer asked for these reworded instead, so each was rewritten to describe the same fact generically (e.g. "per this project's phase lifecycle," "the test brief," "a layout/behavior read of the Figma screenshot") without depending on a path that won't exist in the delivered tree. This spec (`05-docs-and-release.md`) still names the excluded files explicitly where relevant — that's not a dangling cross-reference, it's the deliberate disclosure of what was excluded and why.
- **Where this commit lands**: on this same `chore/release-prep` branch, before opening the PR to `develop` — not a separate branch, so the branch's own history shows the reasoning.
- **CI status**: `docs/specs/00-project-standards.md` already documents the GitHub-hosted runner's simulator-boot flake as a known, deliberately non-blocking limitation — local `xcodebuild test`/`build` is the real merge gate for every phase including this one.
- **No app code changes in this phase** — nothing here should touch `EnjoeiProducts/` or its test targets. If reconciling the README surfaces an actual code inaccuracy (not expected, but possible), that gets flagged separately rather than silently fixed under a "docs" commit.

## Test plan

Since this phase changes no app code, "testing" it means:
1. Confirm the project still builds after the doc-only commits: `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' build`.
2. Manual read-through: does the new README "AI usage" section actually answer the brief's three questions (boilerplate? refactors? syntax lookups?) with concrete examples, not generic claims?
3. After the untrack commit: `git status` on a clean working tree shows nothing for the five gitignored files even though they still exist on disk (`ls docs/ CLAUDE.md` still shows them locally).
4. After the `main` PR merges: fresh `git clone` of `main` into a scratch directory shows exactly `README.md`, `docs/ARCHITECTURE.md`, `docs/specs/*.md` as documentation — open in Xcode, run on Simulator, confirm it behaves identically to `develop` (this phase touched no app code, so this is a sanity check).
5. Zip the cloned `main` checkout per `docs/CONTEXT_TEST.md`'s delivery instructions.
