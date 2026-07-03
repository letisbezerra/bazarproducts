import XCTest
@testable import EnjoeiProducts

final class AppFontTests: XCTestCase {
    func test_uiFont_semibold_loadsTheBundledMontserratInstance() {
        let font = AppFont.uiFont(size: 12, weight: .semibold)

        XCTAssertEqual(font.fontName, "Montserrat-SemiBold")
    }

    func test_uiFont_bold_loadsTheBundledMontserratInstance() {
        let font = AppFont.uiFont(size: 22, weight: .bold)

        XCTAssertEqual(font.fontName, "Montserrat-Bold")
    }

    func test_uiFont_regular_loadsTheBundledMontserratInstance() {
        let font = AppFont.uiFont(size: 15, weight: .regular)

        XCTAssertEqual(font.fontName, "Montserrat-Regular")
    }

    func test_uiFont_withoutTextStyle_ignoresContentSizeCategory() {
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let font = AppFont.uiFont(size: 12, weight: .regular, compatibleWith: accessibilityTraits)

        XCTAssertEqual(font.pointSize, 12)
    }

    func test_uiFont_withTextStyle_scalesUpForLargerContentSizeCategory() {
        let defaultTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

        let baseFont = AppFont.uiFont(size: 12, weight: .regular, textStyle: .caption1, compatibleWith: defaultTraits)
        let scaledFont = AppFont.uiFont(
            size: 12,
            weight: .regular,
            textStyle: .caption1,
            compatibleWith: accessibilityTraits
        )

        XCTAssertGreaterThan(scaledFont.pointSize, baseFont.pointSize)
    }
}
