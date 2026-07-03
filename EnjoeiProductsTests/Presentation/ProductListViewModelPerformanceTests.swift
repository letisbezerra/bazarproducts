import XCTest
@testable import EnjoeiProducts

@MainActor
final class ProductListViewModelPerformanceTests: XCTestCase {
    // Matches the scale noted in docs/PLAN.md for the real liked-products account
    // (~1,262 items across 32 pages) once several pages have accumulated.
    private static let largeDatasetSize = 1_300

    func test_updateSearchText_performsWellAgainstLargeProductList() async {
        let repository = ProductsRepositoryMock()
        let useCase = DefaultFetchLikedProductsUseCase(repository: repository)
        let items = (0..<Self.largeDatasetSize).map { index in
            Product(
                id: index,
                title: "produto número \(index)",
                imageURL: nil,
                currentPrice: 10.0,
                originalPrice: nil,
                discountPercentage: nil
            )
        }
        repository.resultsByPage[1] = .success(ProductsPage(items: items, hasNextPage: false))
        let sut = ProductListViewModel(useCase: useCase)
        await sut.loadInitialPage()

        // Exercises the real production path end to end (debounce included, since
        // that's genuine UX latency, not a test artifact) across a broad match, a
        // narrow match, and a no-match query.
        let queries = ["produto", "número 42", "consulta sem nenhum resultado"]

        // XCTest's measure {} can't safely bridge to async work here: wait(for:timeout:)
        // blocks the main actor's executor, which is also what the awaited Task needs to
        // resume on -- a real deadlock, not a slow measurement. Timing directly with
        // async/await (same style as the rest of this test target's debounce waits)
        // avoids that while still producing an objective, repeatable number.
        let start = Date()
        for query in queries {
            sut.updateSearchText(query)
            try? await Task.sleep(nanoseconds: 300_000_000)
            _ = sut.displayedProducts
        }
        let elapsed = Date().timeIntervalSince(start)

        print("ProductListViewModelPerformanceTests: \(queries.count) searches over " +
            "\(Self.largeDatasetSize) items took \(elapsed)s")

        // ~300ms x 3 queries (~0.9s) is the expected floor, dominated by the debounce
        // itself, not the filter. A generous ceiling catches an actual regression in the
        // filter's cost without being flaky under CI scheduling noise.
        XCTAssertLessThan(elapsed, 2.0)
    }
}
