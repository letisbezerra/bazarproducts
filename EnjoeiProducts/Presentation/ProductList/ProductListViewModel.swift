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
        didSet { onChange?() }
    }

    private(set) var isLoadingNextPage = false

    var onChange: (() -> Void)?

    private var products: [Product] = []
    private var currentPage = 1
    private var hasNextPage = true
    private var searchDebounceTask: Task<Void, Never>?

    private let useCase: FetchLikedProductsUseCase
    private let logger: AppLogger

    init(useCase: FetchLikedProductsUseCase, logger: AppLogger = AppLogger()) {
        self.useCase = useCase
        self.logger = logger
    }

    var displayedProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter {
            $0.title.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var showsNoResultsState: Bool {
        state == .loaded && !searchText.isEmpty && displayedProducts.isEmpty
    }

    func loadInitialPage() async {
        state = .loading
        currentPage = 1

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
        guard currentRow >= products.count - Self.prefetchThreshold else { return }

        let nextPage = currentPage + 1
        isLoadingNextPage = true
        onChange?()

        Task {
            do {
                let page = try await useCase.execute(page: nextPage)
                products += page.items
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
