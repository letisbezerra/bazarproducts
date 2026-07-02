# Implementation plan — EnjoeiProducts

This is the durable copy of our build-out plan, kept in the repo so any future session (or reviewer) can pick up exactly where we left off without relying on chat history. Update the status table below as phases complete — it doubles as visible progress tracking, in the spirit of the shape-up/transparency culture `docs/TEST_BRIEF.md` describes.

## Status

| Phase | Branch | Spec doc | Status |
|---|---|---|---|
| 0 — Standards & tooling | `feature/project-standards` | `docs/specs/00-project-standards.md` | Merged — [#1](https://github.com/letisbezerra/bazarproducts/pull/1) |
| 1 — Core & networking | `feature/core-networking` | `docs/specs/01-core-networking.md` | Merged — [#2](https://github.com/letisbezerra/bazarproducts/pull/2) |
| 2 — Domain & Data | `feature/domain-data` | `docs/specs/02-domain-data.md` | Merged — [#3](https://github.com/letisbezerra/bazarproducts/pull/3) |
| 3 — Product list screen | `feature/product-list-screen` | `docs/specs/03-product-list-screen.md` | Not started |
| 4 — UI tests, accessibility & performance | `feature/ui-tests-and-polish` | `docs/specs/04-ui-tests-and-polish.md` | Not started |
| 5 — Docs & release | `chore/release-prep` (or direct on `develop`) | `docs/specs/05-docs-and-release.md` | Not started |

## Context

This is the Enjoei iOS Pleno technical test: a single screen (liked products list) with loading, infinite pagination, and local search, evaluated against the job's own responsibilities/requirements (Swift + Apple ecosystem, Gitflow, SOLID/Clean Architecture, unit **and UI** tests, observability, clear technical docs, performance/UX — see `docs/TEST_BRIEF.md` for the literal requirements). Setup already done: converted the Xcode template from SwiftUI to UIKit (`AppDelegate`/`SceneDelegate`/placeholder `ProductListViewController`), written `docs/ARCHITECTURE.md`, `docs/TEST_BRIEF.md`, `README.md`, `CLAUDE.md`, and set up Gitflow (`main`/`develop`, both pushed to `origin`). No feature code exists yet.

We hit the real API directly to remove guesswork before planning the Data layer:
- `GET https://www.enjoei.com.br/api/v5/users/enjoei-pro/products/liked?page=N` returns `{ products: [...], pagination: {...}, title, empty_state }`.
- `pagination` = `{ total_entries, page_size, current_page, prev_page, next_page }`. `next_page` is `null` on the last page (confirmed by requesting an out-of-range page — the API clamps to the last valid page and returns `next_page: null`, not an error). **This replaces the "empty page = no more pages" heuristic from the original architecture doc with an exact signal.**
- `image_public_id` returned by the API **is already** the base64 string the image CDN expects (verified by base64-decoding it into an `s3://photos.enjoei.com.br/products/...jpg` path). Building the final image URL is a straight concatenation: `https://photos.enjoei.com.br/public/{size}/{image_public_id}` — no extra base64 encoding needed on our side.
- `price` = `{ listed: Double, sale?: Double }` — `sale` is simply absent (not null) when there's no discount. Discount % = `(listed - sale) / listed`.

This changes two things versus the original `docs/ARCHITECTURE.md` draft, reconciled as part of this plan: (1) pagination stop-condition is `pagination.next_page == nil`, not "empty page"; (2) `ImageURLBuilder` is pure string concatenation, not a base64-encoding utility. We're also reversing the doc's earlier "UI tests out of scope" call — the job posting explicitly lists "testes unitários **e de interface do usuário**" as a responsibility, so Phase 4 below adds a small XCUITest suite instead of skipping it.

Each phase below is one Gitflow feature branch off `develop`, merged back via PR when its tests pass. This mirrors how the job's shape-up/transparency culture expects work to be visible in increments, not delivered as one giant diff.

## Phase lifecycle: start → middle → end

Every phase in this plan — no exceptions — goes through the same three stages before its PR merges. This sequence is the actual process contract for this project; don't skip or reorder steps within a stage.

### Start

1. Check for pending/uncommitted changes (`git status`). Resolve or commit them before doing anything else — never branch off a dirty tree.
2. Confirm `develop` is up to date with `origin/develop` (`git fetch`, then compare/`git pull`).
3. Create the phase's feature branch off the now-current `develop`.

### Middle

1. Re-read `docs/TEST_BRIEF.md` (requirements), `docs/ARCHITECTURE.md` (architecture decisions), this file (the plan), and any other doc/code relevant to the phase.
2. Check the intended solution is still coherent with all of the above. If something drifted since the plan was written (e.g. a fact discovered from the real API), reconcile it now, before writing anything — don't carry a stale assumption into the spec.
3. Once coherent: write `docs/specs/NN-phase-name.md` — **first commit on the branch, before any `.swift` file**. Each spec covers: goal/scope, inputs, outputs (public types/function signatures being introduced), error/edge cases to handle, files to be created or changed, and the list of test cases that will prove it. This is reviewed before implementation starts.
4. Implement exactly what the spec describes.

### End

1. If the phase produces something testable, run a test plan: the automated tests the spec listed, plus manual verification where automated tests can't cover it (e.g. comparing the running app against the Figma states). Running these myself isn't enough — hand over a concrete, numbered step-by-step (exact menu items/shortcuts in Xcode, exact test names, what result to expect) so the developer can personally validate on her own Xcode + Simulator before the phase is considered done. Passing tests I ran and reported is not the same as her having verified it.
2. Check coherence again: does the implementation actually match the spec? If anything diverged during implementation, update the spec doc now so it stays true, not aspirational.
3. Run a rigorous review before the PR exists, not after: the `finish-task` skill (QA/merge-readiness validation) and the `code-review` skill (correctness bugs, reuse/simplification findings on the diff). Fix what they surface.
4. Check for conflicts with `develop` (`git fetch` + a merge preview) and resolve any *before* opening the PR, never after.
5. Open the PR to `develop`, with a description documenting what changed and why. Update the status table at the top of this file.

Spec docs live in `docs/specs/`, numbered to match phase order. They stay in the repo after merge as a paper trail of what was decided and why.

## Phase 0 — Standards & tooling (`feature/project-standards`)

Goal: lock in conventions before writing feature code, and add the CI differential the job posting mentions.

Spec: `docs/specs/00-project-standards.md` — which SwiftLint rules and why, exact Kingfisher version/SPM URL, and the CI workflow's trigger/steps, written before touching the project file.

- Add SwiftLint via SPM build tool plugin (or a `.swiftlint.yml` + Run Script phase if the plugin proves finicky in this Xcode version), with a pragmatic ruleset: force-unwrap disallowed outside tests, line length, no unused imports. This is the "Clean Code / SOLID" requirement made mechanically enforced instead of just prose in the README.
- Add Kingfisher via Swift Package Manager (project already has no SPM dependencies).
- Add `.github/workflows/ci.yml`: `xcodebuild test` on push/PR to `develop`/`main`, using the existing `EnjoeiProducts` scheme and `EnjoeiProductsTests` target. Addresses the "noções de CI/CD" differential from the posting, and gives every later phase a real merge gate instead of a self-reported "tests pass."
- No app code changes in this phase — verification is "CI workflow runs green on an empty/no-op test."

## Phase 1 — Core & networking (`feature/core-networking`)

Spec: `docs/specs/01-core-networking.md` — `HTTPClient` protocol signature, `NetworkError` cases and what triggers each one, `ImageURLBuilder` input/output contract (with the real `image_public_id` sample as a worked example), `AppLogger` categories.

Files (under `EnjoeiProducts/Core/`):
- `HTTPClient.swift` — protocol `func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T`, so `ProductsRepositoryImpl` (Phase 2) and its tests never touch `URLSession` directly.
- `URLSessionHTTPClient.swift` — the real implementation, built with `URLComponents`/`URLQueryItem` (per the architecture doc's security section, avoids manual string concatenation for query params).
- `Endpoint.swift` — small struct (path, query items, an `HTTPMethod` enum defaulting to `.get`) instead of hardcoding the full URL per call.
- `NetworkError.swift` — 4 flat, `Equatable` cases (`invalidResponse`, `decoding`, `http(status:)`, `transport`) with no associated `Error` payload, so the ViewModel (Phase 3) can show one generic message without leaking payload/stack traces (matches the security section already written); the underlying `Error` is logged at the mapping site instead of carried in the type.
- `ImageURLBuilder.swift` — `static func url(imagePublicId: String, size: String = "500x500") -> URL?`, pure concatenation as confirmed above.
- `AppLogger.swift` — a concrete struct (`log(_:category:)`) wrapping `os.Logger`, with categories `.network`/`.viewModel`. This is the observability requirement from the job posting; no third-party SDK.

Tests (`EnjoeiProductsTests/Core/`): `URLSessionHTTPClientTests` (covers request building and all `NetworkError` mapping paths), `ImageURLBuilderTests` (with/without a real `image_public_id` sample from the live API response captured above), `AppLoggerTests`.

## Phase 2 — Domain & Data (`feature/domain-data`)

Spec: `docs/specs/02-domain-data.md` — `Product` entity shape, `ProductsRepository` protocol contract, exact DTO field mapping against the real payload captured in the Context section, and the discount-percentage formula.

Files:
- `Domain/Entities/Product.swift` — `id`, `title`, `imageURL: URL?`, `currentPrice: Double`, `originalPrice: Double?`, `discountPercentage: Int?`. No formatting logic here (formatting is a Presentation concern, kept out of Domain per the dependency rule already documented).
- `Domain/Repositories/ProductsRepository.swift` — protocol `func fetchLikedProducts(page: Int) async throws -> ProductsPage`, where `ProductsPage = (items: [Product], hasNextPage: Bool)`.
- `Domain/UseCases/FetchLikedProductsUseCase.swift` — thin pass-through to the repository; kept because Clean Architecture with an explicit UseCase boundary is literally what the job posting asks for, even though the logic itself is trivial for this single screen.
- `Data/DTO/ProductsResponseDTO.swift` (`products`, `pagination`), `ProductDTO.swift` (`id`, `title`, `image_public_id`, `price: PriceDTO`), `PriceDTO.swift` (`listed`, `sale: Double?`), `PaginationDTO.swift` (`nextPage: Int?` via `CodingKeys` from `next_page`) — field names matched to the real payload captured above, not guessed.
- `Data/Mappers/ProductMapper.swift` — DTO → `Product`, computing `discountPercentage` and calling `ImageURLBuilder`.
- `Data/Repositories/ProductsRepositoryImpl.swift` — implements `ProductsRepository` using `HTTPClient` + the mapper; `hasNextPage` comes straight from `pagination.nextPage != nil`.

Tests (`EnjoeiProductsTests/`): `ProductMapperTests` (with discount, without discount — using the real "no sale field" case found in the sample data), `ProductsRepositoryImplTests` (success, malformed JSON, non-2xx HTTP, last-page/`next_page == nil`) via an `HTTPClientMock` (protocol-based, no real network calls, per the testing strategy already in the architecture doc).

## Phase 3 — Product list screen (`feature/product-list-screen`)

Spec: `docs/specs/03-product-list-screen.md` — `ProductListViewModel` state machine (states + transitions), pagination trigger contract, search filter rules, and the UIKit/SwiftUI split for `EmptyStateView` with its closure-based interface.

Files (`Presentation/ProductList/`):
- `ProductListViewModel.swift` — `@MainActor` class with a `State` enum (`.loading`, `.loaded`, `.error(String)`); holds the full loaded list, `searchText`, and a computed `displayedProducts` (case/diacritic-insensitive local filter on `title`); `loadNextPageIfNeeded(currentRow:)` for prefetching; `hasMorePages`; `clearSearch()`. This is the piece with the most business logic, so it's also the piece with the most tests.
- `ProductListViewController.swift` — replaces the current placeholder. `UICollectionView` with Compositional Layout (2-column grid), `NSDiffableDataSourceSnapshot`, `UICollectionViewDataSourcePrefetching` for infinite scroll (per the architecture doc's explicit call to avoid `scrollViewDidScroll`), a top-pinned search bar, skeleton cells while `state == .loading`, and an `EmptyStateView` overlay when `displayedProducts` is empty due to search (not during initial loading/error).
- `ProductCell.swift` — Kingfisher-loaded image (cancels on reuse automatically), conditional discount badge, price labels (strikethrough + sale price, or single price).
- `Views/SkeletonCell.swift` (UIKit).
- `Views/EmptyStateView.swift` — **SwiftUI** (title "ué, não encontramos nadinha", subtitle, "limpar busca" button, mascot image), embedded into the UIKit hierarchy via `UIHostingController`. Deliberate hybrid: this view is static (no scroll, no performance-critical path), so it's a low-risk place to demonstrate the SwiftUI differential listed in the job posting without touching the UIKit-only grid/pagination/search that carries the actual complexity. The "limpar busca" action is passed in as a closure calling `viewModel.clearSearch()`, keeping the SwiftUI view free of ViewModel/UIKit knowledge.
- Wire `SceneDelegate.swift` to construct the real `ProductListViewController` with its dependencies (manual init injection, per the "no DI framework" decision already in the architecture doc) instead of the current bare placeholder.

Tests (`EnjoeiProductsTests/Presentation/`): `ProductListViewModelTests` — initial load success/failure, pagination accumulates and stops exactly when `hasNextPage` is false, search filters correctly, search with no match flips to the empty state, `clearSearch()` restores the full list. Uses a `ProductsRepositoryMock` (protocol-based).

## Phase 4 — UI tests, accessibility & performance (`feature/ui-tests-and-polish`)

Spec: `docs/specs/04-ui-tests-and-polish.md` — the four flows to be scripted as XCUITest scenarios (given/when/then), accessibility labels to add, and the performance check's pass/fail threshold.

- `EnjoeiProductsUITests/ProductListUITests.swift` covering the four mandatory Figma flows end-to-end: launch → skeletons → results render; scroll to bottom → more cells load; type a matching query → filtered grid; type a non-matching query → "ué, não encontramos nadinha" → tap "limpar busca" → full grid returns. This directly satisfies the job posting's "testes unitários e de interface do usuário" line.
- Accessibility pass: `accessibilityLabel`s on price/discount/search elements, Dynamic Type sanity check on `ProductCell`.
- Performance check: with ~1,262 real liked products (32 pages) once several pages are loaded, confirm the local search filter stays smooth on the main thread; move filtering to a background queue only if it actually shows jank (don't pre-optimize).

## Phase 5 — Docs & release (`chore/release-prep` off `develop`, or direct on `develop`)

Spec: `docs/specs/05-docs-and-release.md` — checklist of what must be reconciled between `ARCHITECTURE.md`/README and what was actually built, and the exact release checklist (CI status, PR, zip).

- Update `docs/ARCHITECTURE.md` with the two corrections found during Phase 2 (pagination via `next_page`, image URL as plain concatenation) and the Phase 4 addition of UI tests, so the doc matches what was actually built (job posting: "manter a documentação técnica sempre atualizada").
- Fill in the README's "AI usage" section for real, based on what was actually delegated to AI vs. done by hand across these phases.
- Confirm CI is green on `develop`, open the `develop` → `main` PR, then zip the project per `docs/TEST_BRIEF.md`'s delivery instructions.

## Verification (per phase)

- Phases 0–3: `xcodebuild -project EnjoeiProducts.xcodeproj -scheme EnjoeiProducts -destination 'platform=iOS Simulator,name=iPhone 17' test` must pass locally. The CI workflow itself is a known non-blocking check on the GitHub-hosted runner (simulator-boot flake, documented in `docs/specs/00-project-standards.md`) — local test success is the actual merge gate, not the CI badge.
- Phase 3 end: run the app in Simulator and manually walk all 6 Figma states (loading, results, pagination, search empty, search filled, no results) side by side with the provided screenshots.
- Phase 4: run the UI test target locally (`Cmd+U` with `EnjoeiProductsUITests` enabled) before merging.
- Phase 5: fresh `git clone` + open in Xcode + run, to confirm the README's instructions actually work end to end.
