@testable import EnjoeiProducts

final class ProductsRepositoryMock: ProductsRepository {
    var result: Result<ProductsPage, Error>?
    private(set) var requestedPages: [Int] = []

    func fetchLikedProducts(page: Int) async throws -> ProductsPage {
        requestedPages.append(page)

        switch result {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        case .none:
            fatalError("ProductsRepositoryMock.result not set before calling fetchLikedProducts(page:)")
        }
    }
}
