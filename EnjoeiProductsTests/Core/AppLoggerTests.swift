import XCTest
@testable import EnjoeiProducts

final class AppLoggerTests: XCTestCase {
    func test_log_doesNotCrashForAnyCategory() {
        let logger = AppLogger()

        logger.log("test message", category: .network)
        logger.log("test message", category: .viewModel)
    }
}
