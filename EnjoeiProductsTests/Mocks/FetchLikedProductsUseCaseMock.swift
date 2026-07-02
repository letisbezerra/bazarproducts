@testable import EnjoeiProducts

enum FetchLikedProductsUseCaseMockError: Error {
    case noStubForPage(Int)
}

final class FetchLikedProductsUseCaseMock: FetchLikedProductsUseCase {
    var resultsByPage: [Int: Result<ProductsPage, Error>] = [:]
    private(set) var requestedPages: [Int] = []

    func execute(page: Int) async throws -> ProductsPage {
        requestedPages.append(page)

        guard let result = resultsByPage[page] else {
            throw FetchLikedProductsUseCaseMockError.noStubForPage(page)
        }

        switch result {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        }
    }
}
