import XCTest
@testable import EnjoeiProducts

@MainActor
final class ProductListViewModelTests: XCTestCase {
    func test_loadInitialPage_onSuccess_setsLoadedStateAndProducts() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1)], hasNextPage: false))
        let sut = ProductListViewModel(useCase: useCase)

        await sut.loadInitialPage()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1)])
    }

    func test_loadInitialPage_onFailure_setsErrorState() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .failure(NetworkError.transport)
        let sut = ProductListViewModel(useCase: useCase)

        await sut.loadInitialPage()

        guard case .error = sut.state else {
            return XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func test_loadNextPageIfNeeded_accumulatesItemsAndStopsWhenNoNextPage() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1)], hasNextPage: true))
        useCase.resultsByPage[2] = .success(makePage(items: [makeProduct(id: 2)], hasNextPage: false))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        sut.loadNextPageIfNeeded(currentRow: 0)
        await waitForPagination()

        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1), makeProduct(id: 2)])

        sut.loadNextPageIfNeeded(currentRow: 1)
        await waitForPagination()

        XCTAssertEqual(useCase.requestedPages, [1, 2])
    }

    func test_loadNextPageIfNeeded_whileAlreadyLoading_doesNotIssueSecondRequest() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1)], hasNextPage: true))
        useCase.resultsByPage[2] = .success(makePage(items: [makeProduct(id: 2)], hasNextPage: true))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        sut.loadNextPageIfNeeded(currentRow: 0)
        sut.loadNextPageIfNeeded(currentRow: 0)
        await waitForPagination()

        XCTAssertEqual(useCase.requestedPages, [1, 2])
    }

    func test_loadNextPageIfNeeded_onFailure_keepsLoadedItemsAndAllowsRetry() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1)], hasNextPage: true))
        useCase.resultsByPage[2] = .failure(NetworkError.transport)
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        sut.loadNextPageIfNeeded(currentRow: 0)
        await waitForPagination()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1)])

        useCase.resultsByPage[2] = .success(makePage(items: [makeProduct(id: 2)], hasNextPage: false))
        sut.loadNextPageIfNeeded(currentRow: 0)
        await waitForPagination()

        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1), makeProduct(id: 2)])
        XCTAssertEqual(useCase.requestedPages, [1, 2, 2])
    }

    func test_updateSearchText_filtersDisplayedProductsByTitle() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(
            items: [makeProduct(id: 1, title: "vestido azul"), makeProduct(id: 2, title: "sapato preto")],
            hasNextPage: false
        ))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        sut.updateSearchText("vestido")
        await waitForDebounce()

        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1, title: "vestido azul")])
    }

    func test_updateSearchText_isDiacriticInsensitive() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(
            items: [makeProduct(id: 1, title: "vestido café com leite")],
            hasNextPage: false
        ))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        sut.updateSearchText("cafe")
        await waitForDebounce()

        XCTAssertEqual(sut.displayedProducts.count, 1)
    }

    func test_showsNoResultsState_isTrueOnlyWhenLoadedWithNonEmptySearchAndNoMatches() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1, title: "vestido azul")], hasNextPage: false))
        let sut = ProductListViewModel(useCase: useCase)

        XCTAssertFalse(sut.showsNoResultsState)

        await sut.loadInitialPage()
        XCTAssertFalse(sut.showsNoResultsState)

        sut.updateSearchText("sapato")
        await waitForDebounce()

        XCTAssertTrue(sut.showsNoResultsState)
    }

    func test_clearSearch_restoresFullListAndClearsNoResultsState() async {
        let useCase = FetchLikedProductsUseCaseMock()
        useCase.resultsByPage[1] = .success(makePage(items: [makeProduct(id: 1, title: "vestido azul")], hasNextPage: false))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()
        sut.updateSearchText("sapato")
        await waitForDebounce()
        XCTAssertTrue(sut.showsNoResultsState)

        sut.clearSearch()

        XCTAssertFalse(sut.showsNoResultsState)
        XCTAssertEqual(sut.displayedProducts, [makeProduct(id: 1, title: "vestido azul")])
    }

    // MARK: - Helpers

    private func makeProduct(id: Int, title: String = "item") -> Product {
        Product(id: id, title: title, imageURL: nil, currentPrice: 10.0, originalPrice: nil, discountPercentage: nil)
    }

    private func makePage(items: [Product], hasNextPage: Bool) -> ProductsPage {
        ProductsPage(items: items, hasNextPage: hasNextPage)
    }

    private func waitForPagination() async {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    private func waitForDebounce() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}
