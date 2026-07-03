import SwiftUI
import UIKit

/// The system's `.secondaryLabel` (RGB 60,60,67 @ 60% alpha) measures ~3.44:1
/// contrast against a white background -- below WCAG AA's 4.5:1 minimum for
/// text this small. This solid gray measures ~7:1, used wherever secondary
/// text is small enough for that ratio to matter (not for placeholder/hint
/// text, which HIG treats as non-critical).
enum ReadableGray {
    static let uiColor: UIColor = UIColor(white: 0.35, alpha: 1)
    static let color: Color = Color(white: 0.35)
}
