@testable import EnjoeiProducts

enum ProductsRepositoryMockError: Error {
    case noStubForPage(Int)
}

final class ProductsRepositoryMock: ProductsRepository {
    var resultsByPage: [Int: Result<ProductsPage, Error>] = [:]
    private(set) var requestedPages: [Int] = []

    func fetchLikedProducts(page: Int) async throws -> ProductsPage {
        requestedPages.append(page)

        guard let result = resultsByPage[page] else {
            throw ProductsRepositoryMockError.noStubForPage(page)
        }

        switch result {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        }
    }
}
