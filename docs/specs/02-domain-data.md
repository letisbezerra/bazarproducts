# Spec 02 — Domain & Data

Phase 2 of `docs/PLAN.md`. Builds on Phase 1's `HTTPClient`/`NetworkError`/`ImageURLBuilder` to produce the first layer that knows about products.

## Goal

Model `Product` as a pure Domain entity, define the `ProductsRepository` contract the ViewModel (Phase 3) will depend on, and implement it against the real API using DTOs that match the confirmed payload exactly — no guessed field names or types.

## Inputs

Real payload reconfirmed by calling `GET https://www.enjoei.com.br/api/v5/users/enjoei-pro/products/liked?page=1` directly (not reused from memory, to avoid a stale assumption):

```json
{
  "products": [
    {
      "id": 113156030,
      "title": "vestido off white zebra agatha",
      "image_public_id": "czM6Ly9waG90b3MuZW5qb2VpLmNvbS5ici9wcm9kdWN0cy8yMzYxMzg0OS9hMzEzOWQ5NzFiNjEyYmE0OGM0NzNmMjUzY2RmMjQxZS5qcGc",
      "price": { "listed": 80.0, "sale": 56.0 }
    }
  ],
  "pagination": {
    "total_entries": 1262,
    "page_size": 40,
    "current_page": 1,
    "prev_page": null,
    "next_page": 2
  },
  "title": "yeyezados",
  "empty_state": { "icon": "...", "title": "...", "subtitle": "...", "action_button": { "url": "...", "label": "..." } }
}
```

Confirmed from this real response:
- `id` is a JSON number (`Int`), not a string.
- `price.sale` is genuinely **absent** (not `null`) on a product with no discount — confirmed on a real item in this same response.
- `pagination.next_page` is `2` on page 1 and (per earlier research already in `docs/PLAN.md`) becomes `null` on the last page — the exact stop condition.
- The response also carries `title` (a header string) and `empty_state` (Enjoei's own "you have zero liked products" state). **Neither is modeled in this phase** — `empty_state` here is the server's "no favorites at all" case, a different concept from this app's local-search "no results" empty state (`docs/ARCHITECTURE.md` §1), which needs no server data at all. Only `products` and `pagination.next_page` are consumed.
- `product_url`, `slug`, `context` fields exist in the payload but are not used by any Figma state — deliberately not mapped into `Product`, per "no dead code."

## Outputs

- `Domain/Entities/Product.swift`
  ```swift
  struct Product: Equatable, Identifiable {
      let id: Int
      let title: String
      let imageURL: URL?
      let currentPrice: Double
      let originalPrice: Double?
      let discountPercentage: Int?
  }
  ```
  No formatting (currency strings, "33% off" text) here — that's a Presentation concern (Phase 3), per the dependency rule in `docs/ARCHITECTURE.md` §2. `currentPrice` is always populated (sale price when discounted, listed price otherwise); `originalPrice`/`discountPercentage` are `nil` together when there's no discount.
- `Domain/Repositories/ProductsRepository.swift`
  ```swift
  struct ProductsPage: Equatable {
      let items: [Product]
      let hasNextPage: Bool
  }

  protocol ProductsRepository {
      func fetchLikedProducts(page: Int) async throws -> ProductsPage
  }
  ```
- `Domain/UseCases/FetchLikedProductsUseCase.swift`
  ```swift
  protocol FetchLikedProductsUseCase {
      func execute(page: Int) async throws -> ProductsPage
  }

  struct DefaultFetchLikedProductsUseCase: FetchLikedProductsUseCase {
      let repository: ProductsRepository
      func execute(page: Int) async throws -> ProductsPage {
          try await repository.fetchLikedProducts(page: page)
      }
  }
  ```
  A thin pass-through. Kept because an explicit UseCase boundary is what the job posting's "Clean Architecture" ask literally names, even though there's no business rule beyond delegation today — this is the one intentional exception to "don't add abstractions beyond what's needed," justified by an explicit external requirement rather than speculation.
- `Data/DTO/PriceDTO.swift`
  ```swift
  struct PriceDTO: Decodable {
      let listed: Double
      let sale: Double?
  }
  ```
- `Data/DTO/ProductDTO.swift`
  ```swift
  struct ProductDTO: Decodable {
      let id: Int
      let title: String
      let imagePublicId: String
      let price: PriceDTO

      enum CodingKeys: String, CodingKey {
          case id, title, price
          case imagePublicId = "image_public_id"
      }
  }
  ```
- `Data/DTO/PaginationDTO.swift`
  ```swift
  struct PaginationDTO: Decodable {
      let nextPage: Int?

      enum CodingKeys: String, CodingKey {
          case nextPage = "next_page"
      }
  }
  ```
  Only `next_page` is decoded — `total_entries`/`page_size`/`current_page`/`prev_page` aren't used by anything in this app.
- `Data/DTO/ProductsResponseDTO.swift`
  ```swift
  struct ProductsResponseDTO: Decodable {
      let products: [ProductDTO]
      let pagination: PaginationDTO
  }
  ```
  `title`/`empty_state` intentionally omitted (see Inputs).
- `Data/Mappers/ProductMapper.swift`
  ```swift
  enum ProductMapper {
      static func map(_ dto: ProductDTO) -> Product
  }
  ```
  Discount logic (revised after code review — see "What actually happened" below): a discount is only computed when `listed > 0`, `sale` exists, `sale >= 0`, and `sale < listed`; and only kept if the resulting `discountPercentage` rounds to something greater than 0. Any input failing one of these guards falls back to `currentPrice = listed`, `originalPrice = nil`, `discountPercentage = nil`. `imageURL` comes from `ImageURLBuilder.url(imagePublicId:)` (Phase 1) — `nil` is a valid, handled state (Phase 3 shows a placeholder), not an error.
- `Data/Repositories/ProductsRepositoryImpl.swift`
  ```swift
  final class ProductsRepositoryImpl: ProductsRepository {
      private let httpClient: HTTPClient
      init(httpClient: HTTPClient)
      func fetchLikedProducts(page: Int) async throws -> ProductsPage
  }
  ```
  Calls `httpClient.send(Endpoint(path: "/users/enjoei-pro/products/liked", queryItems: [URLQueryItem(name: "page", value: String(page))]))`, decodes `ProductsResponseDTO`, maps each `ProductDTO` via `ProductMapper`, and sets `hasNextPage = (response.pagination.nextPage != nil)`.

## Decisions & edge cases

- **Discount edge case**: `price.sale` present but *not* less than `price.listed` (e.g. equal, or a data anomaly where sale > listed) is treated as "no real discount" — `currentPrice = listed`, no badge — rather than showing a 0%-or-negative discount tag.
- **`imageURL == nil`** is not a `Product`-level error — a product with a malformed/empty `image_public_id` still has a title and price worth showing; Phase 3's cell shows a placeholder image, matching how `ImageURLBuilder` was already designed in Phase 1 to return `nil` rather than throw.
- **Pagination**: `hasNextPage` is derived once, in the repository, from `pagination.nextPage != nil` — the ViewModel (Phase 3) never inspects the DTO directly, keeping the `next_page == nil` API quirk contained to this layer.
- **`FetchLikedProductsUseCase`**: no caching, no combining multiple repository calls — a literal pass-through, matching `docs/ARCHITECTURE.md`'s "no business rule beyond delegation" framing already used for this phase's planning.
- **DTO `CodingKeys`**: explicit for every `snake_case` field rather than `.convertFromSnakeCase`, continuing Phase 1's decision to keep decoding explicit and greppable.

## What actually happened (diverged from the original plan)

A rigorous code-review pass on the first implementation found 3 confirmed numeric bugs in the original, simpler discount guard (`guard let sale = dto.price.sale, sale < dto.price.listed`), none observed in the live sample but all reachable with plausible or even ordinary data:

- **Division-by-zero crash**: `listed == 0` with any `sale` below it passed the original guard and reached `(listed - sale) / listed`, producing `Infinity`; `Int(Infinity.rounded())` traps and crashes the app. Reproduced directly in a Swift interpreter.
- **Unvalidated negative prices**: a negative `sale` (e.g. `-10.0`) with a positive `listed` passed the guard with no lower-bound check, producing a negative `currentPrice` and a >100% discount badge (verified: `listed=50, sale=-10` → `currentPrice=-10.0`, `discountPercentage=120`).
- **0%-badge inconsistency**: an ordinary near-equal price pair (e.g. `listed=80.00`, `sale=79.90` — a realistic markdown, not a manufactured edge case) rounds `discountPercentage` to `0` while still setting `originalPrice` non-nil, breaking this doc's own stated invariant that both fields are `nil` together whenever there's no meaningful discount.

Fixed by tightening the guard to `listed > 0, sale >= 0, sale < listed`, and adding a second guard after computing `discountPercentage` that falls back to "no discount" if the rounded percentage isn't greater than 0. Both guards route through a shared private `noDiscountProduct(dto:imageURL:)` helper instead of duplicating the "no discount" `Product` construction. Test cases added: `test_map_withZeroListedPrice_doesNotCrashAndHasNoDiscount`, `test_map_withNegativeSale_treatedAsNoDiscount`, `test_map_withDiscountRoundingToZeroPercent_treatedAsNoDiscount`.

The same review also flagged `EnjoeiProductsTests/Mocks/HTTPClientMock.swift` using `fatalError` on a stub type mismatch or unset result — not reachable by today's tests, but a landmine for Phase 3+ once this mock is reused for more endpoints (a wrong stub would crash the entire test process instead of failing one test). Fixed by throwing a small `HTTPClientMockError` enum instead, which `send(_:)` can propagate normally since it's already `throws`.

Two other review findings were discussed and deliberately left as-is: the endpoint path being inline in `ProductsRepositoryImpl` rather than an `Endpoint` factory (this app has exactly one repository method; extracting a factory now would be speculative), and `FetchLikedProductsUseCase` being a pure pass-through (already justified above by the job posting's explicit Clean Architecture/UseCase requirement, not a technical need).

## Files to be created

- `EnjoeiProducts/Domain/Entities/Product.swift`
- `EnjoeiProducts/Domain/Repositories/ProductsRepository.swift`
- `EnjoeiProducts/Domain/UseCases/FetchLikedProductsUseCase.swift`
- `EnjoeiProducts/Data/DTO/PriceDTO.swift`
- `EnjoeiProducts/Data/DTO/ProductDTO.swift`
- `EnjoeiProducts/Data/DTO/PaginationDTO.swift`
- `EnjoeiProducts/Data/DTO/ProductsResponseDTO.swift`
- `EnjoeiProducts/Data/Mappers/ProductMapper.swift`
- `EnjoeiProducts/Data/Repositories/ProductsRepositoryImpl.swift`

## Test cases

`EnjoeiProductsTests/Data/ProductMapperTests.swift`:
- DTO with `sale < listed` → `currentPrice = sale`, `originalPrice = listed`, correct `discountPercentage`.
- DTO with no `sale` (using the real "no discount" sample product) → `currentPrice = listed`, `originalPrice = nil`, `discountPercentage = nil`.
- DTO with `sale >= listed` (constructed edge case, not from live data) → treated as no discount.
- DTO with a valid `image_public_id` → `imageURL` matches `ImageURLBuilder`'s output exactly.
- DTO with empty `image_public_id` → `imageURL == nil`, mapping still succeeds (no throw).
- DTO with `listed == 0` and a negative `sale` → no crash, treated as no discount (added after code review).
- DTO with a negative `sale` and a positive `listed` → treated as no discount, not a negative price (added after code review).
- DTO with a discount that rounds to 0% (e.g. `listed=80.00`, `sale=79.90`) → treated as no discount (added after code review).

`EnjoeiProductsTests/Data/ProductsRepositoryImplTests.swift` (via a `HTTPClientMock` conforming to `HTTPClient`, no real network calls):
- Success: valid JSON → returns `ProductsPage` with mapped items and `hasNextPage` matching `next_page`.
- `next_page: null` (last page) → `hasNextPage == false`.
- HTTPClient throws `NetworkError.decoding`/`.http`/`.transport` → repository call rethrows the same error (no swallowing).
- Query item `page` is passed through correctly to the `Endpoint`.

`EnjoeiProductsTests/Domain/FetchLikedProductsUseCaseTests.swift`:
- Delegates to the injected `ProductsRepository` and returns its result unchanged (success and failure).

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation test` — all new tests pass, existing tests still pass.
- No manual/UI verification needed — no UI exists yet that depends on this layer (Phase 3).
