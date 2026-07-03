//
//  EnjoeiProductsUITestsLaunchTests.swift
//  EnjoeiProductsUITests
//
//  Created by Leticia Bezerra on 01/07/26.
//

import XCTest

final class EnjoeiProductsUITestsLaunchTests: XCTestCase {

    // Overrides XCTestCase's `class var`; `static` can't override it.
    // swiftlint:disable:next static_over_final_class
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
