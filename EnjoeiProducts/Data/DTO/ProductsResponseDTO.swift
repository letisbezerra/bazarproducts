struct ProductsResponseDTO: Decodable {
    let products: [ProductDTO]
    let pagination: PaginationDTO
}
