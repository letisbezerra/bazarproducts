enum ProductMapper {
    static func map(_ dto: ProductDTO) -> Product {
        let imageURL = ImageURLBuilder.url(imagePublicId: dto.imagePublicId)

        guard let sale = dto.price.sale, sale < dto.price.listed else {
            return Product(
                id: dto.id,
                title: dto.title,
                imageURL: imageURL,
                currentPrice: dto.price.listed,
                originalPrice: nil,
                discountPercentage: nil
            )
        }

        let discountPercentage = Int(((dto.price.listed - sale) / dto.price.listed * 100).rounded())

        return Product(
            id: dto.id,
            title: dto.title,
            imageURL: imageURL,
            currentPrice: sale,
            originalPrice: dto.price.listed,
            discountPercentage: discountPercentage
        )
    }
}
