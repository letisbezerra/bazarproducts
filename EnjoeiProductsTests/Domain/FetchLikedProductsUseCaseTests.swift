import XCTest
@testable import EnjoeiProducts

final class FetchLikedProductsUseCaseTests: XCTestCase {
    func test_execute_onSuccess_returnsRepositoryResultUnchanged() async throws {
        let repository = ProductsRepositoryMock()
        let expectedPage = ProductsPage(items: [], hasNextPage: true)
        repository.result = .success(expectedPage)
        let sut = DefaultFetchLikedProductsUseCase(repository: repository)

        let page = try await sut.execute(page: 3)

        XCTAssertEqual(page, expectedPage)
        XCTAssertEqual(repository.requestedPages, [3])
    }

    func test_execute_onFailure_rethrowsRepositoryError() async {
        let repository = ProductsRepositoryMock()
        repository.result = .failure(NetworkError.transport)
        let sut = DefaultFetchLikedProductsUseCase(repository: repository)

        do {
            _ = try await sut.execute(page: 1)
            XCTFail("Expected NetworkError.transport to be rethrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .transport)
        } catch {
            XCTFail("Expected NetworkError but got \(error)")
        }
    }
}
