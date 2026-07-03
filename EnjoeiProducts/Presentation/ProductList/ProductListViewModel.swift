import Foundation

@MainActor
final class ProductListViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case error(String)
    }

    private static let prefetchThreshold = 5
    private static let searchDebounceNanoseconds: UInt64 = 250_000_000

    private(set) var state: State = .loading {
        didSet { onChange?() }
    }

    private(set) var searchText: String = "" {
        didSet {
            cachedDisplayedProducts = nil
            onChange?()
        }
    }

    private(set) var isLoadingNextPage = false

    var onChange: (() -> Void)?

    private var products: [Product] = [] {
        didSet { cachedDisplayedProducts = nil }
    }
    private var cachedDisplayedProducts: [Product]?
    private var currentPage = 1
    private var hasNextPage = true
    private var searchDebounceTask: Task<Void, Never>?

    private let useCase: FetchLikedProductsUseCase
    private let logger: AppLogger

    init(useCase: FetchLikedProductsUseCase, logger: AppLogger = AppLogger()) {
        self.useCase = useCase
        self.logger = logger
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayedProducts: [Product] {
        if let cachedDisplayedProducts { return cachedDisplayedProducts }

        let query = trimmedSearchText
        let result = query.isEmpty
            ? products
            : products.filter { $0.title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        cachedDisplayedProducts = result
        return result
    }

    var showsNoResultsState: Bool {
        state == .loaded && !trimmedSearchText.isEmpty && displayedProducts.isEmpty
    }

    func loadInitialPage() async {
        state = .loading
        currentPage = 1

        if UITestingFlag.artificialDelay.isEnabled {
            // Real API, no mock -- fast responses can make the loading state too transient
            // for ProductListUITests to observe. XCUITest's own post-launch attach/sync
            // overhead alone measured at ~9s in one run (before the test's first assertion
            // even executes), so a short delay gets outlasted by that overhead alone,
            // independent of network speed. 15s gives real margin over that.
            try? await Task.sleep(nanoseconds: 15_000_000_000)
        }

        do {
            let page = try await useCase.execute(page: currentPage)
            products = page.items
            hasNextPage = page.hasNextPage
            state = .loaded
        } catch {
            logger.log("Initial page load failed: \(error)", category: .viewModel)
            state = .error("Não foi possível carregar os produtos. Tente novamente.")
        }
    }

    func loadNextPageIfNeeded(currentRow: Int) {
        guard state == .loaded, hasNextPage, !isLoadingNextPage else { return }
        // currentRow indexes into displayedProducts (what the collection view actually shows,
        // possibly search-filtered) -- comparing it against the full products.count instead would
        // make pagination silently stall whenever a search filters the list down.
        guard currentRow >= displayedProducts.count - Self.prefetchThreshold else { return }

        let nextPage = currentPage + 1
        isLoadingNextPage = true
        onChange?()

        Task {
            do {
                let page = try await useCase.execute(page: nextPage)
                let existingIds = Set(products.map(\.id))
                products += page.items.filter { !existingIds.contains($0.id) }
                currentPage = nextPage
                hasNextPage = page.hasNextPage
            } catch {
                logger.log("Pagination load failed for page \(nextPage): \(error)", category: .viewModel)
            }
            isLoadingNextPage = false
            onChange?()
        }
    }

    func updateSearchText(_ text: String) {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: Self.searchDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            searchText = text
        }
    }

    func clearSearch() {
        searchDebounceTask?.cancel()
        searchText = ""
    }
}
