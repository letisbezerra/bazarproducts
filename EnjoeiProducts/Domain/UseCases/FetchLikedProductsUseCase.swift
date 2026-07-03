protocol FetchLikedProductsUseCase {
    func execute(page: Int) async throws -> ProductsPage
}

struct DefaultFetchLikedProductsUseCase: FetchLikedProductsUseCase {
    let repository: ProductsRepository

    func execute(page: Int) async throws -> ProductsPage {
        try await repository.fetchLikedProducts(page: page)
    }
}
