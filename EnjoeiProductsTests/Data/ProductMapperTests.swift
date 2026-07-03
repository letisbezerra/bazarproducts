import XCTest
@testable import EnjoeiProducts

final class ProductMapperTests: XCTestCase {
    private let realImagePublicId = "czM6Ly9waG90b3MuZW5qb2VpLmNvbS5ici9wcm9kdWN0cy8yMzYxMzg0OS9hMzEzOWQ5NzFiNjEyYmE0OGM0NzNmMjUzY2RmMjQxZS5qcGc"

    func test_map_withDiscount_computesCurrentAndOriginalPriceAndPercentage() {
        let dto = ProductDTO(
            id: 113_156_030,
            title: "vestido off white zebra agatha",
            imagePublicId: realImagePublicId,
            price: PriceDTO(listed: 80.0, sale: 56.0)
        )

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 56.0)
        XCTAssertEqual(product.originalPrice, 80.0)
        XCTAssertEqual(product.discountPercentage, 30)
    }

    func test_map_withoutSaleField_hasNoDiscount() {
        let dto = ProductDTO(
            id: 116_295_601,
            title: "cropped preto strass",
            imagePublicId: realImagePublicId,
            price: PriceDTO(listed: 50.0, sale: nil)
        )

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 50.0)
        XCTAssertNil(product.originalPrice)
        XCTAssertNil(product.discountPercentage)
    }

    func test_map_withSaleNotLessThanListed_treatedAsNoDiscount() {
        let dto = ProductDTO(
            id: 1,
            title: "anomalous item",
            imagePublicId: realImagePublicId,
            price: PriceDTO(listed: 50.0, sale: 50.0)
        )

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 50.0)
        XCTAssertNil(product.originalPrice)
        XCTAssertNil(product.discountPercentage)
    }

    func test_map_withValidImagePublicId_matchesImageURLBuilderOutput() {
        let dto = ProductDTO(
            id: 1,
            title: "item",
            imagePublicId: realImagePublicId,
            price: PriceDTO(listed: 10.0, sale: nil)
        )

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.imageURL, ImageURLBuilder.url(imagePublicId: realImagePublicId))
    }

    func test_map_withEmptyImagePublicId_hasNilImageURLButStillMaps() {
        let dto = ProductDTO(id: 1, title: "item", imagePublicId: "", price: PriceDTO(listed: 10.0, sale: nil))

        let product = ProductMapper.map(dto)

        XCTAssertNil(product.imageURL)
        XCTAssertEqual(product.title, "item")
    }

    func test_map_withZeroListedPrice_doesNotCrashAndHasNoDiscount() {
        let dto = ProductDTO(id: 1, title: "anomalous item", imagePublicId: "", price: PriceDTO(listed: 0.0, sale: -1.0))

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 0.0)
        XCTAssertNil(product.originalPrice)
        XCTAssertNil(product.discountPercentage)
    }

    func test_map_withNegativeSale_treatedAsNoDiscount() {
        let dto = ProductDTO(id: 1, title: "anomalous item", imagePublicId: "", price: PriceDTO(listed: 50.0, sale: -10.0))

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 50.0)
        XCTAssertNil(product.originalPrice)
        XCTAssertNil(product.discountPercentage)
    }

    func test_map_withDiscountRoundingToZeroPercent_treatedAsNoDiscount() {
        let dto = ProductDTO(id: 1, title: "item", imagePublicId: "", price: PriceDTO(listed: 80.0, sale: 79.9))

        let product = ProductMapper.map(dto)

        XCTAssertEqual(product.currentPrice, 80.0)
        XCTAssertNil(product.originalPrice)
        XCTAssertNil(product.discountPercentage)
    }
}
