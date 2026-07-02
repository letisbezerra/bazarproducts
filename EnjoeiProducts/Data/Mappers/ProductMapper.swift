import Foundation

enum ProductMapper {
    static func map(_ dto: ProductDTO) -> Product {
        let imageURL = ImageURLBuilder.url(imagePublicId: dto.imagePublicId)
        let listed = dto.price.listed

        guard
            listed > 0,
            let sale = dto.price.sale,
            sale >= 0,
            sale < listed
        else {
            return noDiscountProduct(dto: dto, imageURL: imageURL)
        }

        let discountPercentage = Int(((listed - sale) / listed * 100).rounded())

        guard discountPercentage > 0 else {
            return noDiscountProduct(dto: dto, imageURL: imageURL)
        }

        return Product(
            id: dto.id,
            title: dto.title,
            imageURL: imageURL,
            currentPrice: sale,
            originalPrice: listed,
            discountPercentage: discountPercentage
        )
    }

    private static func noDiscountProduct(dto: ProductDTO, imageURL: URL?) -> Product {
        Product(
            id: dto.id,
            title: dto.title,
            imageURL: imageURL,
            currentPrice: dto.price.listed,
            originalPrice: nil,
            discountPercentage: nil
        )
    }
}
