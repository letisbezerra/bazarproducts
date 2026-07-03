struct ProductDTO: Decodable {
    let id: Int
    let title: String
    let imagePublicId: String
    let price: PriceDTO

    enum CodingKeys: String, CodingKey {
        case id, title, price
        case imagePublicId = "image_public_id"
    }
}
