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
}
