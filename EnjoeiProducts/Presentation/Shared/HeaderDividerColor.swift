import UIKit

/// Single source of truth for the `HeaderDivider` asset name, matching the
/// pattern already used by `BrandColor` and `ReadableGray`.
enum HeaderDividerColor {
    static let uiColor: UIColor = UIColor(named: "HeaderDivider") ?? .separator
}
