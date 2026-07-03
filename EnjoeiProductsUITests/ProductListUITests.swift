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

        XCTAssertTrue(app.otherElements["skeletonGridView"].waitForExistence(timeout: 1))

        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 15))
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 15))
    }

    @MainActor
    func test_scrollToBottom_loadsNextPage() throws {
        app.launch()
        let collectionView = app.collectionViews["productCollectionView"]
        XCTAssertTrue(collectionView.cells.firstMatch.waitForExistence(timeout: 15))

        let initialCount = collectionView.cells.count
        for _ in 0..<8 {
            collectionView.swipeUp()
        }

        let loadedMoreCells = NSPredicate { _, _ in collectionView.cells.count > initialCount }
        wait(for: [XCTNSPredicateExpectation(predicate: loadedMoreCells, object: nil)], timeout: 30)

        XCTAssertGreaterThan(collectionView.cells.count, initialCount)
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
