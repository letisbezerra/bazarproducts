# Spec 04 — UI tests, accessibility & performance

Phase 4 of `docs/PLAN.md`. Adds automated coverage for the four mandatory flows from `docs/CONTEXT_TEST.md` §1 that unit tests can't reach (they exercise `ProductListViewModel` in isolation, not the real `UICollectionView`/search field/empty-state wiring), closes the one real accessibility gap left after Phase 3's HIG audit (Dynamic Type), and gets an objective, automated number for the search-filter performance question instead of a subjective "felt smooth" call.

Built in three independently committed sub-steps, same pattern as Phase 3 — each sub-step gets its own build/test cycle and a validation hand-off before moving to the next, per `docs/PLAN.md`'s "large phase in sub-steps" rule.

## Goal

Prove — with an automated, repeatable test, not just a manual walkthrough — that: (1) the four mandatory Figma flows work end-to-end through the real UI; (2) the screen remains usable at large Dynamic Type sizes; (3) local search filtering stays fast once the list is large.

## What's already done (not repeated here)

Checked against Phase 3's HIG audit (`docs/DESIGN_GUIDE.md` §7) before writing this spec, per the phase-lifecycle "Middle" step of reconciling before writing anything:
- `accessibilityLabel` on price/discount (`ProductCell.swift:96-103`) — done.
- Search field (`placeholder = "buscar"`) and the inline "limpar busca" button (visible title) — both already read correctly by VoiceOver via standard UIKit behavior, no gap.
- Contrast (`ReadableGray`) and 44×44pt tap targets (`ExpandedHitAreaButton`) — done.

So this phase's real accessibility scope is narrower than `docs/PLAN.md`'s original Phase 4 bullet: just Dynamic Type (sub-step 2 below).

## Sub-step 1 — XCUITest flows

### Inputs
- The real, running app — no mocking at this layer (that's what `ProductListViewModelTests` already covers). Tests drive the actual `URLSessionHTTPClient` against the real Enjoei API, same as a manual run.
- The 4 mandatory flows from `docs/CONTEXT_TEST.md` §1: loading, results, infinite pagination, search (filled + no-match).

### Outputs
- `EnjoeiProductsUITests/ProductListUITests.swift`, one test method per flow:
  1. `test_launch_showsSkeletonThenResults` — skeleton visible right after launch, then at least one product cell visible within a timeout.
  2. `test_scrollToBottom_loadsNextPage` — record the cell count, scroll to the last cell, assert the count increases (pagination fired).
  3. `test_search_withMatch_filtersGrid` — type a query known to match real liked products, assert the grid still shows cells and the empty-state view is absent.
  4. `test_search_withNoMatch_showsEmptyStateThenClearRestoresGrid` — type a query guaranteed not to match (e.g. a random UUID string), assert the "ué, não encontramos nadinha" text and empty-state "limpar busca" button appear, tap it, assert the full grid returns.

### Decisions & edge cases
- **Test data is the real, live liked-products list**, not a stub — `docs/CONTEXT_TEST.md` never asks for a UI-test-specific mock server, and the account's liked list is large enough (~1,262 items / 32 pages) to make pagination and a true no-match search both reachable without one. Trade-off, stated plainly: these tests depend on network + account state; if the liked list ever empties out, tests 1-3 need a fixture rethink. Accepted for this phase's scope.
- **Disambiguating the two "limpar busca" buttons** — the diagnostic spike during Phase 3 already found that a query matching zero products makes *both* the inline button and the empty-state's button visible with the identical accessible name "limpar busca", which breaks a plain `app.buttons["limpar busca"]` lookup (`XCTAssertion` "Multiple matching elements found"). Fix: give each button a distinct `accessibilityIdentifier` (`"inlineClearSearchButton"` / `"emptyStateClearButton"`) without touching their shared visible text/VoiceOver label, and query by identifier in the new tests instead of by label.
- **New `accessibilityIdentifier`s needed for reliable querying** (identifiers are silent to VoiceOver, purely for test/automation use, so this doesn't touch the HIG audit's VoiceOver work): `collectionView` → `"productCollectionView"`, `skeletonView` → `"skeletonGridView"`, the two clear buttons above. No identifier needed on `ProductCell` itself — cell *count* via `collectionView.cells.count` is enough to prove pagination and filtering, we don't need to identify individual cells.
- **Waiting instead of sleeping**: all four tests use `XCTestCase.wait(for:timeout:)`/`waitForExistence(timeout:)` against real elements, never a fixed `sleep()`, since network latency is variable.

### Test cases
Same as the 4 outputs above — this sub-step's tests ARE the deliverable, not a separate list.

## Sub-step 2 — Dynamic Type support

### Inputs
- `ProductCell.swift`, `EmptyStateView.swift`, `ProductListViewController.swift` — every `UILabel`/`Text` currently on a fixed-pt `AppFont` (confirmed via a full-project grep before this spec: zero existing usage of `adjustsFontForContentSizeCategory`, `UIFontMetrics`, or `dynamicTypeSize` anywhere in the codebase).

### Outputs
- `AppFont.uiFont(size:weight:)` (`Presentation/Shared/AppFont.swift`) gains an optional `textStyle: UIFont.TextStyle` parameter; when provided, the returned font is wrapped through `UIFontMetrics(forTextStyle:).scaledFont(for:)` so it scales with the user's content-size setting instead of staying fixed.
- Every `UILabel` in `ProductCell` (`currentPriceLabel`, `originalPriceLabel`, `badgeLabel`) and in `ProductListViewController` (search field placeholder styling aside) sets `adjustsFontForContentSizeCategory = true` and is built via the new `textStyle`-aware call (`.caption1` for price/badge text, matching their small-text role).
- `EmptyStateView` (SwiftUI) already scales by default under SwiftUI's `Font` unless a fixed size was forced — `AppFont.font(size:weight:)` currently hardcodes a raw point size with no text-style relative scaling either, so it gets the same `textStyle`-aware treatment as its UIKit counterpart for consistency.
- `ProductCell`'s Auto Layout: price pill and badge currently use fixed-height constraints (`heightAnchor.constraint(equalToConstant: 22)` for `badgeLabel`) that would clip text at large accessibility sizes. Relax to `greaterThanOrEqualToConstant` with a fitting content-hugging priority so the pill/badge grow instead of clipping.

### Decisions & edge cases
- **Card image/grid geometry stays fixed** — only text-bearing elements scale. `ProductCell`'s square aspect ratio and the 2-column grid are a deliberate Figma-matched layout choice; Apple's own HIG guidance is that image/media containers aren't expected to reflow with Dynamic Type, only their accompanying text.
- **No automated snapshot test for this** — Dynamic Type layout correctness is inherently visual (does text clip/overlap at `.accessibility5`?), so verification is manual: run the app with Settings → Accessibility → Larger Text set to its maximum, walk the same states as the Phase 3 End-stage manual check. Documented as a manual step in Verification below, not skipped.
- **`AppFontTests.swift` (existing)** gets one addition: `uiFont(size:weight:textStyle:)` with a `textStyle` returns a font whose `pointSize` is `>=` the base size when `UIContentSizeCategory` is forced to `.accessibilityExtraExtraExtraLarge` in the test (via a category-scoped `UITraitCollection`), proving the scaling actually engages — this part IS automatable even though full-layout verification isn't.

### Test cases
- `AppFontTests`: new case above (scaling engages for a large content-size category, base font/weight unaffected when no `textStyle` is passed — existing 3 tests keep passing unchanged).

## Sub-step 3 — Performance check

### Inputs
- `ProductListViewModel.displayedProducts`/`updateSearchText(_:)` (Phase 3, unchanged) — the exact code path already used in production, not a reimplementation for the test.

### Outputs
- `EnjoeiProductsTests/Presentation/ProductListViewModelPerformanceTests.swift`: seeds a `ProductsRepositoryMock` to return a large synthetic dataset (~1,300 `Product` items, matching the real account's scale noted in `docs/PLAN.md`), loads it into the view model, then uses `XCTest`'s `measure { }` around repeated `updateSearchText(_:)` calls (a mix of matching/non-matching queries) to get a concrete, CI-reproducible timing baseline — replacing a subjective "felt smooth while scrolling" manual judgment with a number that fails loudly if it regresses later.

### Decisions & edge cases
- **Automated over manual**: `docs/PLAN.md`'s original wording ("confirm the local search filter stays smooth... move filtering to a background queue only if it actually shows jank") implied a manual Instruments session. An `XCTest measure` block is preferred here: it's automated, reruns on every future change, and gives an actual number instead of a one-time subjective read — a better fit for "don't pre-optimize" than a hallway judgment call, since it tells us objectively whether sub-step 3 needs to do anything else at all.
- **No background-queue change unless the measured baseline shows it's warranted** — per the "don't pre-optimize" instruction already in `docs/PLAN.md`, this sub-step does not move filtering off the main thread speculatively. If `measure` shows the ~1,300-item filter comfortably under a frame budget (which is expected — it's a single `String.range(of:)` scan per item, not a network or disk operation), no production code changes at all; the test itself, sitting in the repo, is the deliverable.

### Test cases
- The `measure` block above is the test. Pass/fail threshold: `XCTest`'s default baseline-deviation check (first run on the developer's machine sets the baseline; CI doesn't have to enforce a hard number given the documented simulator-boot flakiness already noted in `docs/specs/00-project-standards.md`).

## Files to be created / changed

Created:
- `EnjoeiProductsUITests/ProductListUITests.swift`
- `EnjoeiProductsTests/Presentation/ProductListViewModelPerformanceTests.swift`

Changed:
- `EnjoeiProducts/Presentation/ProductList/ProductListViewController.swift` (accessibility identifiers on `collectionView`/`skeletonView`/both clear buttons; `textStyle`-aware fonts where applicable)
- `EnjoeiProducts/Presentation/ProductList/ProductCell.swift` (`textStyle`-aware fonts, `adjustsFontForContentSizeCategory`, relaxed height constraints on `badgeLabel`)
- `EnjoeiProducts/Presentation/ProductList/Views/EmptyStateView.swift` (`textStyle`-aware fonts)
- `EnjoeiProducts/Presentation/Shared/AppFont.swift` (new optional `textStyle` parameter on both `uiFont` and `font`)
- `EnjoeiProductsTests/Presentation/AppFontTests.swift` (new Dynamic Type scaling test case)

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation test` — all existing tests plus the new performance test pass.
- `EnjoeiProductsUITests` target run via `Cmd+U` (or `-only-testing:EnjoeiProductsUITests`) — all 4 new UI tests pass against the real API. Requires network access and a non-empty liked-products account, same precondition as any manual run.
- Manual: Settings → Accessibility → Larger Text → drag to maximum, relaunch, walk the same 6 states as the Phase 3 End-stage check — confirm no text clipping/overlap in `ProductCell`, the empty state, or the search row.
