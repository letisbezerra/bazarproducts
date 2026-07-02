struct ProductsPage: Equatable {
    let items: [Product]
    let hasNextPage: Bool
}

protocol ProductsRepository {
    func fetchLikedProducts(page: Int) async throws -> ProductsPage
}
