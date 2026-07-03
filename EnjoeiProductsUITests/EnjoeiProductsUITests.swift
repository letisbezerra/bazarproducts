//
//  EnjoeiProductsUITests.swift
//  EnjoeiProductsUITests
//
//  Created by Leticia Bezerra on 01/07/26.
//

import XCTest

final class EnjoeiProductsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
