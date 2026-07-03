import XCTest
@testable import EnjoeiProducts

final class ExpandedHitAreaButtonTests: XCTestCase {
    func test_pointInside_belowMinimumSize_expandsHitAreaToMinimum() {
        let button = ExpandedHitAreaButton(frame: CGRect(x: 0, y: 0, width: 120, height: 34))

        // 5pt above/below the button's own bounds: outside the visible frame,
        // but within the 44pt-minimum expanded hit area.
        XCTAssertTrue(button.point(inside: CGPoint(x: 60, y: -4), with: nil))
        XCTAssertTrue(button.point(inside: CGPoint(x: 60, y: 38), with: nil))
    }

    func test_pointInside_wellOutsideExpandedArea_staysFalse() {
        let button = ExpandedHitAreaButton(frame: CGRect(x: 0, y: 0, width: 120, height: 34))

        XCTAssertFalse(button.point(inside: CGPoint(x: 60, y: -20), with: nil))
        XCTAssertFalse(button.point(inside: CGPoint(x: 60, y: 54), with: nil))
    }

    func test_pointInside_alreadyAtOrAboveMinimumSize_doesNotExpand() {
        let button = ExpandedHitAreaButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        XCTAssertFalse(button.point(inside: CGPoint(x: 22, y: -1), with: nil))
        XCTAssertTrue(button.point(inside: CGPoint(x: 22, y: 22), with: nil))
    }
}
