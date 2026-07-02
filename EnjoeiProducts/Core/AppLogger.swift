import Foundation
import os

enum LogCategory: String {
    case network
    case viewModel
}

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "EnjoeiProducts"

    func log(_ message: String, category: LogCategory) {
        let logger = Logger(subsystem: Self.subsystem, category: category.rawValue)
        logger.log("\(message, privacy: .public)")
    }
}
