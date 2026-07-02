import XCTest
@testable import EnjoeiProducts

final class AppLoggerTests: XCTestCase {
    func test_log_doesNotCrashForAnyCategory() {
        let logger = OSLogAppLogger()

        logger.log("test message", category: .network)
        logger.log("test message", category: .viewModel)
    }
}
