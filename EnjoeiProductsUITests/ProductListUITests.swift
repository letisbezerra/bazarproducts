import XCTest

final class ProductListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    @MainActor
    func test_launch_showsSkeletonThenResults() throws {
        // Real API, no mock -- on a fast connection the loading state can come and go
        // before this test even attaches, so the first fetch is deliberately slowed down
        // (test-only, see ProductListViewModel.loadInitialPage) to make it observable.
        app.launchArguments = ["-uiTestingArtificialDelay"]
        app.launch()

        // Generous timeout: XCUITest's own post-launch attach overhead alone has measured
        // ~9s before this assertion even starts polling, on top of whatever the artificial
        // delay above is holding.
        XCTAssertTrue(app.otherElements["skeletonGridView"].waitForExistence(timeout: 10))

        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 20))
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 20))
    }

    @MainActor
    func test_scrollToBottom_loadsNextPage() throws {
        app.launchArguments = ["-uiTestingExposesLoadedItemCount"]
        app.launch()
        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 15))

        // collectionView.cells.count only reflects on-screen cells (UICollectionView
        // recycles the rest), so it never grows no matter how much is actually loaded --
        // it's the wrong signal for "did pagination add items". accessibilityValue is a
        // test-only hook (see ProductListViewController.applySnapshot) carrying the real,
        // total displayed-item count instead.
        let initialTotal = collectionView.value as? String

        // A fixed swipe count is fragile against real page-size/screen-height variance --
        // too few swipes and the prefetch threshold (currentRow >= count - 5) is never
        // crossed, and the test just burns the whole wait below for nothing. 15 swipes
        // gives generous margin past that threshold regardless of exact page size.
        for _ in 0..<15 {
            collectionView.swipeUp()
        }

        let loadedMoreItems = NSPredicate { _, _ in (collectionView.value as? String) != initialTotal }
        wait(for: [XCTNSPredicateExpectation(predicate: loadedMoreItems, object: nil)], timeout: 40)

        XCTAssertNotEqual(collectionView.value as? String, initialTotal)
    }

    @MainActor
    func test_search_withMatch_filtersGrid() throws {
        app.launch()
        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 15))

        let searchField = app.textFields["buscar"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("a")

        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["ué, não encontramos nadinha"].exists)
    }

    @MainActor
    func test_search_withNoMatch_showsEmptyStateThenClearRestoresGrid() throws {
        app.launch()
        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 15))

        let searchField = app.textFields["buscar"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(UUID().uuidString)

        let emptyStateText = app.staticTexts["ué, não encontramos nadinha"]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5))

        let emptyStateClearButton = app.buttons["emptyStateClearButton"]
        XCTAssertTrue(emptyStateClearButton.exists)
        emptyStateClearButton.tap()

        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(emptyStateText.exists)
    }
}
