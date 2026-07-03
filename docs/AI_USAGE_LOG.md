# AI usage log (working draft)

This is a running, internal log of concretely how AI was used across the project — kept so the README's required "AI superpowers" section (`docs/CONTEXT_TEST.md` §5) can be written at Phase 5 by consolidating real entries, not by reconstructing months of work from memory. **This file is not the deliverable itself** — it's raw material for it. Entries are added as work happens, in the same PR as the work they describe, same as `docs/specs/*.md`.

Each entry should be concrete enough to answer the brief's actual question ("foi pra gerar boilerplate inicial? pra refatorar lógica complexa? pra tirar dúvida de sintaxe?") — not "AI helped with the code," but what specifically it generated, and what specifically required human judgment/review/correction on top of that.

## Phase 0 — Standards & tooling

- SwiftLint ruleset, Kingfisher SPM integration, and the `.github/workflows/ci.yml` workflow were AI-drafted from a spec written first (`docs/specs/00-project-standards.md`).
- CI needed several human-in-the-loop iterations to get a GitHub-hosted runner to boot a simulator reliably (Xcode version selection, job timeout, diagnostic steps) — not a one-shot generation, several rounds of "run it, read the failure, adjust."

## Phase 1 — Core & networking

- `HTTPClient`/`URLSessionHTTPClient`/`Endpoint`/`NetworkError`/`ImageURLBuilder`/`AppLogger` implemented by AI against a spec (`docs/specs/01-core-networking.md`) written first, including a worked example against a real `image_public_id` sample pulled from the live API (not invented).
- A code-review pass surfaced real findings that were fixed in a dedicated commit (`Apply code review fixes to Phase 1`) before merge — AI both wrote the original code and did the review pass, but the decision on which findings were worth fixing was reviewed by hand.

## Phase 2 — Domain & Data

- `Product`, `ProductsRepository`, DTOs, mapper, and repository implementation generated against a spec (`docs/specs/02-domain-data.md`), with exact field names matched to a real captured API payload rather than guessed.
- Same code-review-then-fix pattern as Phase 1 (`Apply code review fixes to Phase 2`).

## Phase 3 — Product list screen

- ViewModel, ViewController, cells, skeleton view, and the SwiftUI `EmptyStateView` were implemented in four sub-steps against `docs/specs/03-product-list-screen.md`, each sub-step built, tested, and hand-validated before moving to the next (per the phase-lifecycle rule in `docs/PLAN.md`).
- **Real bug found by root-cause debugging, not guesswork**: a large, unexplained gap around the search bar turned out to be an Auto Layout ambiguity (neither the search row nor the collection view had two independently-pinned edges). Diagnosed by instrumenting the running app directly — temporary background colors and `print(view.frame)`/`print(view.constraints)` statements captured via `xcrun simctl launch --console-pty` — not by trial-and-error constraint tweaking.
- **A wrong first fix was caught and reverted**: an initial hypothesis (`UISearchBar`'s intrinsic height) was tested, had zero visible effect, and was discarded in favor of the actual root cause above.
- **A code-review claim was verified against real execution and refuted**: a finder flagged that `UIFont(name: "Montserrat-SemiBold", ...)` would return nil for a variable font; running `AppFontTests` on a real simulator proved all three weights load correctly, so the "finding" was dropped instead of acted on.
- **A contrast claim was corrected after the developer pushed back**: an early answer asserted `.secondaryLabel` was "already calibrated" for accessibility without doing the math. Pressed for a real number, the actual WCAG relative-luminance calculation showed ~3.44:1 — below the 4.5:1 minimum for small text — and the claim was retracted and fixed (`ReadableGray`), not quietly revised.
- **Real brand assets sourced and adapted, not invented**: the header logo mark was pulled from Enjoei's own public PWA manifest icon, its color verified against the Figma-confirmed `#61005D`, then recolored/composited with a small Python/Pillow script (run in a local venv) to match the Figma circular mark. The "no results" mascot was provided directly by the developer via Xcode's asset catalog after AI confirmed the API's own `empty_state.icon` field wasn't a usable match.
- **A full Apple HIG audit** (contrast ratios calculated by formula against real semantic-color RGBA values, tap-target sizes measured via debug prints rather than eyeballed) was requested by the developer and produced concrete, cited fixes (`ExpandedHitAreaButton`, `ReadableGray`, `ProductCell` accessibility label) — the developer explicitly descoped one candidate improvement (an in-field microphone/dictation button) after AI laid out its real cost, choosing instead to rely on and verify the OS's built-in keyboard dictation.
- **A documentation coherence audit**, requested by the developer, cross-checked `ARCHITECTURE.md`/`CONTEXT_TEST.md`/`DESIGN_GUIDE.md`/`PLAN.md`/`CLAUDE.md`/`README.md` against each other and against the real code, surfacing two real, previously-untracked staleness gaps in `ARCHITECTURE.md` (folder structure, and two decisions that had already been reversed elsewhere without updating this doc) — both fixed on the spot rather than left for Phase 5.
- Every fix in this phase was validated by the developer herself in Simulator/Xcode via an explicit numbered checklist before being committed — nothing was taken on AI's self-report of "tests pass."

## Still to log

- Phase 4 (UI tests, accessibility, performance) and Phase 5 (docs/release) work, once done.
- Anything the developer did by hand outside these sessions that isn't visible here (only she can add that).
