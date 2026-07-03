import SwiftUI
import UIKit

/// Single source of truth for the `BrandPurple` asset name, so a typo or a future
/// asset-catalog rename is caught in one place instead of 6 scattered string literals.
enum BrandColor {
    static let uiColor: UIColor = UIColor(named: "BrandPurple") ?? .black
    static let color: Color = Color("BrandPurple")
}
