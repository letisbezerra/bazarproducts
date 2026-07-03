import Foundation

/// Launch arguments used by ProductListUITests to make otherwise-hard-to-observe app state
/// (a transient loading screen, an item count invisible in the on-screen cell count) testable,
/// without changing real-launch behavior. Never set outside a UI test target.
enum UITestingFlag: String {
    case artificialDelay = "-uiTestingArtificialDelay"
    case exposesLoadedItemCount = "-uiTestingExposesLoadedItemCount"

    var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(rawValue)
    }
}
