import XCTest
@testable import EnjoeiProducts

final class ImageURLBuilderTests: XCTestCase {
    // swiftlint:disable:next line_length
    private let realImagePublicId = "czM6Ly9waG90b3MuZW5qb2VpLmNvbS5ici9wcm9kdWN0cy82NTMwNzkxLzlmZGY5ZWZjNTk5NTdkMDY4YjU4YmFjMzNmMmNmM2YxLmpwZw"

    func test_url_buildsExpectedURLForRealSample() {
        let url = ImageURLBuilder.url(imagePublicId: realImagePublicId)

        XCTAssertEqual(
            url?.absoluteString,
            "https://photos.enjoei.com.br/public/500x500/\(realImagePublicId)"
        )
    }

    func test_url_returnsNilForEmptyImagePublicId() {
        XCTAssertNil(ImageURLBuilder.url(imagePublicId: ""))
    }
}
