import XCTest
@testable import EnjoeiProducts

final class ProductsRepositoryImplTests: XCTestCase {
    private let realImagePublicId = "czM6Ly9waG90b3MuZW5qb2VpLmNvbS5ici9wcm9kdWN0cy8yMzYxMzg0OS9hMzEzOWQ5NzFiNjEyYmE0OGM0NzNmMjUzY2RmMjQxZS5qcGc"

    func test_fetchLikedProducts_onSuccess_returnsMappedItemsAndHasNextPage() async throws {
        let httpClient = HTTPClientMock()
        httpClient.result = .success(makeResponse(nextPage: 2))
        let sut = ProductsRepositoryImpl(httpClient: httpClient)

        let page = try await sut.fetchLikedProducts(page: 1)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items.first?.title, "vestido off white zebra agatha")
        XCTAssertTrue(page.hasNextPage)
    }

    func test_fetchLikedProducts_whenNextPageIsNull_hasNextPageIsFalse() async throws {
        let httpClient = HTTPClientMock()
        httpClient.result = .success(makeResponse(nextPage: nil))
        let sut = ProductsRepositoryImpl(httpClient: httpClient)

        let page = try await sut.fetchLikedProducts(page: 32)

        XCTAssertFalse(page.hasNextPage)
    }

    func test_fetchLikedProducts_rethrowsNetworkError() async {
        let httpClient = HTTPClientMock()
        httpClient.result = .failure(NetworkError.decoding)
        let sut = ProductsRepositoryImpl(httpClient: httpClient)

        do {
            _ = try await sut.fetchLikedProducts(page: 1)
            XCTFail("Expected NetworkError.decoding to be rethrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Expected NetworkError but got \(error)")
        }
    }

    func test_fetchLikedProducts_passesPageAsQueryItem() async throws {
        let httpClient = HTTPClientMock()
        httpClient.result = .success(makeResponse(nextPage: nil))
        let sut = ProductsRepositoryImpl(httpClient: httpClient)

        _ = try await sut.fetchLikedProducts(page: 7)

        XCTAssertEqual(httpClient.requestedEndpoints.last?.queryItems, [URLQueryItem(name: "page", value: "7")])
    }

    private func makeResponse(nextPage: Int?) -> ProductsResponseDTO {
        ProductsResponseDTO(
            products: [
                ProductDTO(
                    id: 113_156_030,
                    title: "vestido off white zebra agatha",
                    imagePublicId: realImagePublicId,
                    price: PriceDTO(listed: 80.0, sale: 56.0)
                )
            ],
            pagination: PaginationDTO(nextPage: nextPage)
        )
    }
}
