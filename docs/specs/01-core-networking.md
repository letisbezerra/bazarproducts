# Spec 01 — Core & networking

Phase 1 of `docs/PLAN.md`. First layer with real logic: the pieces every later phase (Data, Presentation) depends on but that don't yet know anything about products.

## Goal

Provide a transport-agnostic HTTP abstraction, typed errors, an image URL builder, and a thin logging wrapper — so `ProductsRepositoryImpl` (Phase 2) and its tests never touch `URLSession` directly, and the ViewModel (Phase 3) never has to interpret raw `Error` values or leak them to the UI.

## Inputs

- Real API contract already confirmed by hitting `GET https://www.enjoei.com.br/api/v5/users/enjoei-pro/products/liked?page=N` directly (documented in `docs/PLAN.md`'s Context section):
  - `image_public_id` is already the exact base64 string the CDN expects — building the final URL is pure concatenation, no encoding on our side.
  - No API key/auth header required (public endpoint).
- `docs/ARCHITECTURE.md`'s security section: no manual string concatenation for query parameters — must go through `URLComponents`/`URLQueryItem`.
- No existing networking code in the repo (this is the first layer).

## Outputs

Files under `EnjoeiProducts/Core/`:

- `HTTPClient.swift`
  ```swift
  protocol HTTPClient {
      func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
  }
  ```
- `Endpoint.swift` — small struct, not a hardcoded URL per call:
  ```swift
  enum HTTPMethod: String {
      case get = "GET"
  }

  struct Endpoint {
      let path: String
      let queryItems: [URLQueryItem]
      let method: HTTPMethod
  }
  ```
- `URLSessionHTTPClient.swift` — real implementation:
  - Builds the request via `URLComponents` (base host + `endpoint.path` + `endpoint.queryItems`), never manual string interpolation.
  - Validates the response is an `HTTPURLResponse` with a 2xx status before attempting to decode; anything else maps to `NetworkError.http(status:)`.
  - Decodes with `JSONDecoder` (default key strategy — DTOs in Phase 2 will use explicit `CodingKeys` for `snake_case` fields rather than `.convertFromSnakeCase`, so decoding stays explicit and greppable).
  - Any `URLSession` throw (offline, timeout, cancelled) maps to `NetworkError.transport`, logging the underlying `Error` via `AppLogger` at the mapping site (not carried in the enum — see below).
  - Any `DecodingError` maps to `NetworkError.decoding`, same logging treatment.
- `NetworkError.swift`
  ```swift
  enum NetworkError: Error, Equatable {
      case invalidResponse
      case http(status: Int)
      case decoding
      case transport
  }
  ```
  Kept as a flat, associated-value-free-where-possible enum so it's trivially `Equatable` and assertable in tests. The underlying `Error` (if any) is logged via `AppLogger` at the point of mapping, not carried in the type the ViewModel switches on — the ViewModel only ever needs to know *which* of these 4 things happened, not the raw `Error`.
- `ImageURLBuilder.swift`
  ```swift
  enum ImageURLBuilder {
      static func url(imagePublicId: String, size: String = "500x500") -> URL?
  }
  ```
  Pure string concatenation: `https://photos.enjoei.com.br/public/{size}/{imagePublicId}`, then `URL(string:)`. Returns `nil` if either `imagePublicId` or `size` is empty — the mapper (Phase 2) decides what an absent image URL means for `Product`, this type doesn't decide that.
- `AppLogger.swift`
  ```swift
  enum LogCategory: String {
      case network
      case viewModel
  }

  struct AppLogger {
      func log(_ message: String, category: LogCategory)
  }
  ```
  A concrete struct wrapping `os.Logger`, not a protocol — there is exactly one way this app logs today, and no test double exists that needs a substitute. A protocol here would be premature abstraction for a hypothetical future backend (Crashlytics/Sentry) that doesn't exist yet; if one is ever added, extracting a protocol at that point costs one refactor, not two.

## Decisions & error cases

- `NetworkError` has exactly 4 cases, matched to the 4 failure modes an HTTP call can actually have (bad/missing response, non-2xx status, undecodable body, transport-level failure). No catch-all `.unknown` case — if something doesn't fit these 4, that's a bug in the mapping logic, not a legitimate 5th outcome to swallow silently.
- `Endpoint.method` is an `HTTPMethod` enum (one case, `.get`, today), not a raw `String` — a `String` default would let a typo (`"Get"`, `"get "`) compile silently and only fail at runtime once it reaches `URLRequest.httpMethod`; the enum closes that off for negligible extra code.
- No retry/backoff logic — out of scope per `docs/ARCHITECTURE.md`; the ViewModel's error state already covers "let the user pull-to-refresh."
- No auth/token handling — the real endpoint needs none (verified directly).

## Files to be created

- `EnjoeiProducts/Core/HTTPClient.swift`
- `EnjoeiProducts/Core/Endpoint.swift`
- `EnjoeiProducts/Core/URLSessionHTTPClient.swift`
- `EnjoeiProducts/Core/NetworkError.swift`
- `EnjoeiProducts/Core/ImageURLBuilder.swift`
- `EnjoeiProducts/Core/AppLogger.swift`

## Test cases (`EnjoeiProductsTests/Core/`)

- `URLSessionHTTPClientTests` (using `URLProtocol` stubbing, no real network calls):
  - 2xx + valid JSON → decodes successfully.
  - 2xx + malformed JSON → `NetworkError.decoding`.
  - non-2xx status (e.g. 404, 500) → `NetworkError.http(status:)` with the right code.
  - transport failure (stubbed `URLProtocol` error, e.g. offline) → `NetworkError.transport`.
  - query items are present and correctly encoded in the built request (asserted via the stubbed request's URL).
- `ImageURLBuilderTests`:
  - real sample `image_public_id` from the live API response → matches the expected concatenated URL exactly.
  - empty `imagePublicId` → `nil`.
- `AppLoggerTests`: confirms the wrapper doesn't crash for either category. `os.Logger` output isn't practically assertable from XCTest, so this deliberately doesn't claim to verify routing/content — just that logging a message never throws or crashes the caller.

## Verification

- `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation test` — all new tests pass, existing tests still pass.
- No manual/UI verification needed — no UI exists yet that depends on this layer.
