# Spec 05 — Docs & release

Phase 5 of `docs/PLAN.md`. No feature code changes — this phase reconciles documentation with what was actually built and prepares the deliverable Enjoei receives, per `docs/CONTEXT_TEST.md` §5 (zip + README covering technical choices and AI usage).

## Goal

Ship a deliverable that (1) documents the AI-usage transparency the brief explicitly asks for, (2) contains only documentation useful to an outside reviewer (not this project's internal AI-collaboration scaffolding), and (3) has been verified to actually build and run from a clean checkout.

## What's already done (not repeated here)

Confirmed against the current state of the repo before writing this spec, per the phase-lifecycle "Middle" step:
- `docs/ARCHITECTURE.md` reconciliation (pagination via `next_page`, `ImageURLBuilder` as pure concatenation, folder structure, UI-tests reversal) — done during Phase 3's documentation audit, not deferred here.
- `docs/PLAN.md` status table — kept current after every phase merge; Phase 4's row already reads "Merged — [#5]" as of this phase's first commit.

## Inputs

- `docs/AI_USAGE_LOG.md` — the running, per-phase log kept since Phase 3 specifically so this section wouldn't need to be reconstructed from memory.
- `docs/CONTEXT_TEST.md` §5 — the literal ask: "AI superpowers" section must cover concretely how AI was used (boilerplate? refactors? syntax lookups?) — no answer is penalized, the goal is transparency.
- The developer's own decision (this phase) on `docs/DESIGN_GUIDE.md`'s fate: **remove from delivery**, same treatment as the other internal docs — its content (color/font/spacing decisions) is already reflected in the actual code and in `docs/ARCHITECTURE.md` where it matters to a reviewer.

## Outputs

1. **`README.md` "AI usage" section**, replacing the placeholder — a real, concise account of the AI-collaboration pattern used across all 5 phases (spec-first workflow, what AI drafted vs. what required human judgment/correction, concrete examples of both), consolidated from `docs/AI_USAGE_LOG.md` rather than a generic "AI helped with the code."
2. **A delivery cleanup commit** (separate from the doc-writing commit, made only once CI/PR checks for this phase's doc changes are done — see Decisions below) that removes from the working tree: `docs/CONTEXT_TEST.md`, `docs/PLAN.md`, `docs/specs/*.md`, `docs/AI_USAGE_LOG.md`, `docs/DESIGN_GUIDE.md`, `CLAUDE.md`. Only `README.md` and `docs/ARCHITECTURE.md` remain as documentation. All removed files stay recoverable from git history (`develop` branch history is not rewritten).
3. **The `develop` → `main` PR**, opened after the cleanup commit, so `main` reflects exactly what gets zipped.
4. **The delivery zip**, built from a fresh clone of `main` after the PR merges.

## Decisions & edge cases

- **Why two commits (doc-writing, then cleanup) instead of one**: the internal docs (`PLAN.md`, `specs/*.md`, `AI_USAGE_LOG.md`) are still actively useful up through this phase's own PR review — reviewing "did the README match the log" requires the log to still be in the diff. Cleanup happens right before the `main` PR, not before.
- **Where the cleanup commit lands**: on this same `chore/release-prep` branch, as its last commit before opening the PR to `develop` — not a separate branch. This keeps the branch's own history showing the reasoning (a reviewer of this PR can see the log the README was built from, then see it get removed) rather than force-pushing it away.
- **`docs/DESIGN_GUIDE.md`**: explicitly decided this phase (not deferred further) — removed from delivery rather than kept-with-cleanup, since a tone rewrite would just re-derive facts (hex codes, spacing) that are either already in `ARCHITECTURE.md` or directly readable from the code/assets, and the doc's actual content (a "best guess from a screenshot, corrected via Dev Mode crops" narrative) is process history, not a technical reference an evaluator needs.
- **`CLAUDE.md` removed too**: it's the working agreement for *this* AI-assisted session, referenced nowhere by the brief; its content that matters to an evaluator (spec-first workflow, review discipline) is what the "AI usage" README section actually summarizes.
- **CI status**: `docs/specs/00-project-standards.md` already documents the GitHub-hosted runner's simulator-boot flake as a known, deliberately non-blocking limitation — local `xcodebuild test` is the real merge gate for every phase including this one. This phase's own doc-only diff doesn't touch app code, so there's nothing new to test locally beyond confirming the project still builds.
- **No app code changes in this phase** — nothing here should touch `EnjoeiProducts/` or its test targets. If reconciling the README surfaces an actual code inaccuracy (not expected, but possible), that gets flagged separately rather than silently fixed under a "docs" commit.

## Test plan

Since this phase changes no app code, "testing" it means:
1. Confirm the project still builds after the doc-only commits: `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' build`.
2. Manual read-through: does the new README "AI usage" section actually answer the brief's three questions (boilerplate? refactors? syntax lookups?) with concrete examples, not generic claims?
3. After the cleanup commit: `git status`/`ls docs/` shows only `ARCHITECTURE.md` remains under `docs/`, and `CLAUDE.md` is gone from the repo root.
4. After the `main` PR merges: fresh `git clone` of `main` into a scratch directory, open in Xcode, run on Simulator, confirm it behaves identically to `develop` (this phase touched no app code, so this is a sanity check, not expected to find anything).
5. Zip the cloned `main` checkout per `docs/CONTEXT_TEST.md`'s delivery instructions.
