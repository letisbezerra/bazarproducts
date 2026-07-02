struct PaginationDTO: Decodable {
    let nextPage: Int?

    enum CodingKeys: String, CodingKey {
        case nextPage = "next_page"
    }
}
