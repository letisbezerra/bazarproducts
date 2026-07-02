import XCTest
@testable import EnjoeiProducts

final class PriceFormatterTests: XCTestCase {
    func test_string_formatsValueAsBrazilianCurrency() {
        let result = PriceFormatter.string(from: 56.0)

        XCTAssertEqual(result, "R$\u{00A0}56,00")
    }

    func test_string_formatsValueWithCents() {
        let result = PriceFormatter.string(from: 79.9)

        XCTAssertEqual(result, "R$\u{00A0}79,90")
    }
}
