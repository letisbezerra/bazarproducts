# EnjoeiProducts — Architecture Document

Enjoei iOS Pleno technical test — liked products listing screen, with loading, infinite pagination and local search.

## 1. Screen states (mapped from Figma)

The search bar stays **fixed at the top of the grid** in every state below.

| State | Behavior |
|---|---|
| Loading | 2-column grid with skeleton blocks (optional shimmer) in place of the cells |
| Results | 2-column grid: product photo, "33% off" tag (top-right corner, only when there's a discount), price anchored at the bottom (with discount: current price + strikethrough price; without discount: single price) |
| Pagination | Same as Results — as the scroll nears the end, the next page is fetched transparently (no full-screen blocking spinner) |
| Search (empty field) | Full grid keeps showing |
| Search (filled field) | Grid shows only the items whose text matches the search, filtering locally over what's already loaded |
| No Results | Title "ué, não encontramos nadinha", subtitle "que tal recomeçar do começo?", "limpar busca" button, mascot illustration |

## 2. Architecture: Clean Architecture + MVVM

Chosen because it's exactly what the job posting asks for ("modern and testable architecture... MVVM, Clean") and it's the most common pattern in medium/large iOS teams today — it favors testability (business logic isolated from UIKit and networking) without the extra complexity of something like VIPER or TCA, which would be over-engineering for a single screen.

```
Presentation/          → UIKit: ViewController, ViewModel, Cells, custom Views
Domain/                → Pure business logic (no UIKit/networking Foundation imports): Entities, UseCases, Repository protocols
Data/                  → Implementation: DTOs (Codable), DTO→Domain Mappers, RemoteDataSource (URLSession), RepositoryImpl
Core/                  → Generic networking (HTTPClient), image URL building, simple DI (composition root)
```

Dependency rule: `Presentation` knows `Domain`; `Data` implements the protocols defined in `Domain`; `Domain` knows nothing about `Data` or `Presentation`. This allows swapping the data source (e.g. a mock in tests) without touching the ViewModel.

## 3. Technical decisions

- **Concurrency:** `async/await` (Swift Concurrency) instead of Combine — it's Apple's recommended standard for new code since iOS 15/Swift 5.5, simpler to read and to test with async `XCTest`.
- **Networking:** an injected `HTTPClient` protocol (not a concrete class directly), allowing responses to be mocked in tests without hitting the real API. URL building via `URLComponents`/`URLQueryItem` (not string concatenation), avoiding malformed URLs and following Apple's recommended practice to avoid invalid characters in the query.
- **Pagination:** `ProductsRepository.fetchLikedProducts(page: Int)`. The ViewModel holds `currentPage` and `hasMorePages` (becomes `false` when the API returns an empty page). The next page load is triggered via `UICollectionViewDataSourcePrefetching`, not `scrollViewDidScroll`, which is less precise.
- **Search:** 100% local (client-side) filtering over the list already loaded in memory — the API is not called again on search, exactly as requested. No network debounce (there's no network call here), but a small typing debounce (~250ms via a cancellable `Task`) just to avoid recomputing the filter on every keystroke.
- **Images:** Kingfisher (SPM) for disk/memory caching and automatic cancellation on reused cells — avoiding reinventing this is a productivity choice, and it's a mature, widely used library in the iOS market.
- **Layout:** `UICollectionView` with Compositional Layout (2-column grid) + `NSDiffableDataSourceSnapshot`, 100% in code (no Storyboard/XIB) — easier to review in a diff/PR and avoids merge conflicts, a common practice in teams using Git Flow (as Enjoei describes in the job posting).

## 4. Security

The API is public and read-only (GET, no authentication), so there's no secret to protect. Even so:
- HTTPS is mandatory (iOS's default ATS, no `Info.plist` exceptions).
- No user data is ever sent to a server (search is local only) — no server-side injection surface.
- URLs are built via `URLComponents`, never by directly concatenating strings coming from the API.
- Network/parsing errors are handled and translated into generic UI messages (no stack trace or raw payload exposed to the end user).

## 5. Testing strategy

Focus on business logic and success/failure flows, as requested in the test brief:
- **ViewModel:** initial load (success/failure), pagination (accumulates items, stops when a page comes back empty), search (filters correctly, shows the empty state when there's no match, "limpar busca" restores the list).
- **Repository/RemoteDataSource:** correct decoding of the API's JSON, handling of malformed JSON, handling of HTTP errors.
- **Mapper:** DTO → domain entity conversion (discount/tag calculation, price formatting).
- Mocks built via protocol (`HTTPClient`, `ProductsRepository`), with no need for real network calls or extra mocking libraries.

## 6. Proposed folder structure

```
EnjoeiProducts/
  App/                    AppDelegate, SceneDelegate, composition root (manual DI)
  Domain/
    Entities/             Product.swift
    UseCases/             FetchLikedProductsUseCase.swift
    Repositories/          ProductsRepository.swift (protocol)
  Data/
    DTO/                  ProductDTO.swift, ProductsResponseDTO.swift
    Mappers/              ProductMapper.swift
    Network/              HTTPClient.swift, URLSessionHTTPClient.swift, ProductsAPI.swift (endpoints)
    Repositories/          ProductsRepositoryImpl.swift
  Presentation/
    ProductList/
      ProductListViewController.swift
      ProductListViewModel.swift
      ProductCell.swift
      Views/               EmptyStateView.swift, SkeletonCell.swift, SearchBarView.swift
  Core/
    ImageURLBuilder.swift
    Constants.swift
EnjoeiProductsTests/
  ProductListViewModelTests.swift
  ProductsRepositoryImplTests.swift
  ProductMapperTests.swift
  Mocks/                   HTTPClientMock.swift, ProductsRepositoryMock.swift
```

## 7. Out of scope (deliberately)

- Coordinator pattern for navigation — there's only one screen, adding this now would be complexity with no real benefit.
- DI framework (Swinject, etc.) — manual initializer injection is enough and easier to read for the scope of this test.
- UI/snapshot tests — priority given to business logic tests, which is what the brief explicitly asks for.
