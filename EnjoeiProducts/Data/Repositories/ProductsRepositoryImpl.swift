import Foundation

final class ProductsRepositoryImpl: ProductsRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchLikedProducts(page: Int) async throws -> ProductsPage {
        let endpoint = Endpoint(
            path: "/users/enjoei-pro/products/liked",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )

        let response: ProductsResponseDTO = try await httpClient.send(endpoint)

        return ProductsPage(
            items: response.products.map(ProductMapper.map),
            hasNextPage: response.pagination.nextPage != nil
        )
    }
}
