# Spec 03 — Product list screen

Phase 3 of `docs/PLAN.md`. The actual screen: wires `FetchLikedProductsUseCase` (Phase 2) to a `UICollectionView`-based UI, covering every mandatory state in `docs/CONTEXT_TEXT.md` §1 (loading, results, pagination, search, no-results). Built against `docs/DESIGN_GUIDE.md`'s layout/behavior read of the real Figma screenshot — exact pt/color values are still flagged as an open calibration item in `docs/PLAN.md`, not blocking this phase.

## Goal

A single screen that: loads page 1 on appear, shows a skeleton while loading, renders a 2-column product grid, transparently loads more pages near the bottom of the scroll, filters the grid locally by a search field with a debounce, and shows a dedicated empty state when a search has no matches.

## Inputs

- `FetchLikedProductsUseCase.execute(page:) async throws -> ProductsPage` (Phase 2, unchanged).
- `Product` (Phase 2): `id, title, imageURL: URL?, currentPrice: Double, originalPrice: Double?, discountPercentage: Int?`. **This phase adds `Hashable` conformance to it** (currently only `Equatable`) — needed as the item identifier type for `NSDiffableDataSourceSnapshot`. Purely additive, synthesized automatically from existing stored properties, no behavior change.
- `docs/CONTEXT_TEXT.md` §1: the four mandatory states (loading, results, infinite pagination, search with the two sub-states filled/no-match).
- `docs/DESIGN_GUIDE.md`: layout and behavior detail extracted from the real Figma screenshot (badge format `"{n}% off"`, price ordering current-then-strikethrough-original, search bar behavior, "limpar busca" appearing both as an inline link and as the empty-state's button, empty-state structure/order).
- `docs/ARCHITECTURE.md` §3: `UICollectionViewDataSourcePrefetching` for pagination (not `scrollViewDidScroll`), Kingfisher for images, no Combine.

## Outputs

Files under `EnjoeiProducts/Presentation/ProductList/`:

- `ProductListViewModel.swift`
  ```swift
  @MainActor
  final class ProductListViewModel {
      enum State: Equatable {
          case loading
          case loaded
          case error(String)
      }

      private(set) var state: State = .loading
      private(set) var searchText: String = ""
      private(set) var isLoadingNextPage = false
      var onChange: (() -> Void)?

      var displayedProducts: [Product] { get }
      var showsNoResultsState: Bool { get }   // state == .loaded && !searchText.isEmpty && displayedProducts.isEmpty

      init(useCase: FetchLikedProductsUseCase)

      func loadInitialPage() async
      func loadNextPageIfNeeded(currentRow: Int)
      func updateSearchText(_ text: String)   // debounced ~250ms
      func clearSearch()
  }
  ```
  No Combine/`@Published` — a plain closure (`onChange`) the ViewController assigns once, matching `docs/ARCHITECTURE.md`'s existing "async/await instead of Combine" decision extended to UI binding, not just networking.
- `ProductListViewController.swift` — replaces the Phase 0 placeholder. Owns a `UICollectionView` (Compositional Layout, 2 columns) with a `UICollectionViewDiffableDataSource<Section, Product>`, a `UICollectionViewDataSourcePrefetching` conformance calling `viewModel.loadNextPageIfNeeded(currentRow:)`, a plain `UISearchBar` (not `UISearchController` — see Decisions) pinned above the collection view, a `SkeletonGridView` shown during `.loading`, and a `UIHostingController`-embedded `EmptyStateView` shown when `showsNoResultsState`.
- `ProductCell.swift` — Kingfisher-loaded image, conditional discount badge (`"{n}% off"`, hidden when `discountPercentage == nil`), price row (`currentPrice` bold, `originalPrice` strikethrough-gray when non-nil, single price otherwise).
- `Views/SkeletonGridView.swift` — plain `UIView`, a static (non-scrolling) 2-column grid of rounded-rect placeholder blocks built with nested `UIStackView`s. Not a second `UICollectionView`: the skeleton has no interaction and no real items, so the simpler static-view approach avoids a second diffable-data-source/layout setup for content that never changes shape.
- `Views/EmptyStateView.swift` — **SwiftUI**: title "ué, não encontramos nadinha", subtitle "que tal recomeçar do começo?", a pill "limpar busca" button, and a mascot image. The "limpar busca" action is a closure parameter (`onClearSearch: () -> Void`), keeping the SwiftUI view free of `ViewModel`/UIKit knowledge, embedded via `UIHostingController` per `docs/ARCHITECTURE.md`'s deliberate UIKit/SwiftUI hybrid.
- `Formatting/PriceFormatter.swift`
  ```swift
  enum PriceFormatter {
      static func string(from value: Double) -> String   // "R$ 56,00", pt_BR NumberFormatter currency style
  }
  ```
  A `Product`'s raw `Double` prices are formatted only here, in Presentation — kept out of `Domain`/`Data` per the dependency rule already documented.
- `SceneDelegate.swift` (modified) — constructs the real dependency chain instead of the placeholder: `URLSessionHTTPClient()` → `ProductsRepositoryImpl(httpClient:)` → `DefaultFetchLikedProductsUseCase(repository:)` → `ProductListViewModel(useCase:)` → `ProductListViewController(viewModel:)`, manual initializer injection (no DI framework), per the existing decision in `docs/ARCHITECTURE.md`.

## Decisions & edge cases

- **Plain `UISearchBar`, not `UISearchController`** — reconciles `docs/ARCHITECTURE.md`'s earlier `hidesSearchBarWhenScrolling = false` note, written before the Figma screenshot was available. The design shows a custom "limpar busca" text link next to the search field, not the native localized "Cancel" button `UISearchController` provides. Faking that via `searchBar.setValue(_:forKey: "cancelButtonText")` relies on undocumented KVC into a private property — fragile and avoidable. Instead: a plain `UISearchBar` with `showsCancelButton = false`, embedded directly as an always-visible subview above the collection view, plus a custom `UIButton` ("limpar busca") shown only when the search field has text. Since it's a regular subview (not inside `UISearchController`/nav bar), "always visible while scrolling" is the natural behavior, not something to configure.
- **The same "limpar busca" action** is wired to three places per `docs/DESIGN_GUIDE.md`: the inline button next to the search bar, and the button inside `EmptyStateView`. Both call `viewModel.clearSearch()`.
- **Pagination trigger**: `UICollectionViewDataSourcePrefetching.collectionView(_:prefetchItemsAt:)` calls `loadNextPageIfNeeded(currentRow:)` with the maximum row among the prefetched index paths. The ViewModel guards on `state == .loaded`, `hasNextPage`, and `!isLoadingNextPage` — a page already in flight or no more pages silently no-ops, not an error.
- **Pagination failure**: unlike the initial load, a failed page-2+ fetch does **not** flip `state` to `.error` (that would hide the already-loaded grid, contradicting "no full-screen blocking spinner / transparent pagination"). It rolls the attempted page number back so the next scroll-triggered prefetch retries, and logs the error via `AppLogger` (Phase 1) — no user-facing error UI for this case, matching that `docs/CONTEXT_TEXT.md` doesn't describe a pagination-error screen at all.
- **No Figma "error" screen exists at all** (confirmed against both `docs/CONTEXT_TEXT.md` §1 and the shared screenshot's six frames) — an explicit assumption, not from the design: the initial-load error state (`state == .error`) renders a minimal, undesigned view (centered message + a "tentar novamente" retry button triggering `loadInitialPage()` again). `docs/CONTEXT_TEXT.md` §4 does ask that "success/failure flows are protected," so *some* handling is required even without a mandated visual — flagged here rather than silently invented.
- **Search**: `updateSearchText(_:)` debounces ~250ms via a cancellable `Task` (per `docs/ARCHITECTURE.md`'s existing decision) before updating `searchText` and firing `onChange`. `displayedProducts` filters `products` by `title` using `.range(of:options: [.caseInsensitive, .diacriticInsensitive])` — matches accented text (e.g. "café" query matches "Cafe"). `clearSearch()` is immediate, no debounce (cancels any pending debounce task first).
- **Footer loading indicator during pagination**: a small activity indicator in the collection view's footer while `isLoadingNextPage == true`. Not shown in the design screenshot (which only shows already-loaded pagination content, not the in-flight moment) but a low-risk, common infinite-scroll affordance — flagged as our own addition, not a Figma-confirmed element.
- **Mascot image**: SF Symbol placeholder (per the open blocker in `docs/PLAN.md`) until the real asset is exported from Figma.
- **Exact spacing/colors**: HIG-default numbers now (12pt inter-item spacing, 16pt section margins, system fonts, `.label`/`.secondaryLabel` semantic colors, a custom brand-purple `UIColor` approximated from the screenshot for the badge/button/link), explicitly flagged in `docs/PLAN.md` for calibration once the developer compares against the real Figma file.

## Files to be created / changed

Created:
- `EnjoeiProducts/Presentation/ProductList/ProductListViewModel.swift`
- `EnjoeiProducts/Presentation/ProductList/ProductCell.swift`
- `EnjoeiProducts/Presentation/ProductList/Views/SkeletonGridView.swift`
- `EnjoeiProducts/Presentation/ProductList/Views/EmptyStateView.swift`
- `EnjoeiProducts/Presentation/ProductList/Formatting/PriceFormatter.swift`

Changed:
- `EnjoeiProducts/Presentation/ProductList/ProductListViewController.swift` (replaces the Phase 0 placeholder body)
- `EnjoeiProducts/App/SceneDelegate.swift` (real dependency wiring)
- `EnjoeiProducts/Domain/Entities/Product.swift` (add `Hashable`)

## Test cases

`EnjoeiProductsTests/Presentation/ProductListViewModelTests.swift` (via `ProductsRepositoryMock`/a `FetchLikedProductsUseCase` test double, no real network):
- `loadInitialPage()` success → `state == .loaded`, `displayedProducts` matches the mock's items.
- `loadInitialPage()` failure → `state == .error(message)`.
- Pagination: two successful pages accumulate into `displayedProducts`; `loadNextPageIfNeeded` stops issuing calls once `hasNextPage == false`.
- Pagination: a call while `isLoadingNextPage == true` doesn't issue a second concurrent request.
- Pagination failure: `displayedProducts` keeps the already-loaded items, `state` stays `.loaded` (not `.error`), and a retry (next `loadNextPageIfNeeded`) re-attempts the same page.
- Search: `updateSearchText` filters `displayedProducts` by a matching substring; a diacritic-insensitive match (query without accent matches an accented title); `showsNoResultsState == true` only when `state == .loaded && searchText non-empty && displayedProducts.isEmpty`.
- `clearSearch()` restores the full list and `showsNoResultsState == false`.

`EnjoeiProductsTests/Presentation/PriceFormatterTests.swift`:
- A sample value formats to the expected `pt_BR` currency string (e.g. `56.0` → `"R$ 56,00"`).

No unit tests for `ProductListViewController`/`ProductCell`/`SkeletonGridView`/`EmptyStateView` — pure UIKit/SwiftUI composition with no branching logic of their own beyond what the ViewModel/formatter already cover; visual correctness is verified manually against Figma (Phase 3 End) and via XCUITest flows (Phase 4), consistent with `docs/ARCHITECTURE.md` §5's existing testing strategy.

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation test` — all new tests pass, existing tests still pass.
- Manual: run the app in Simulator, walk all states side by side with `docs/DESIGN_GUIDE.md`/the shared screenshot — loading skeleton, results grid, scroll-triggered pagination, search with matches, search with no matches ("ué, não encontramos nadinha" + both "limpar busca" affordances), clearing search restores the grid.
