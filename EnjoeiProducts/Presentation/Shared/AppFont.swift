import SwiftUI
import UIKit

/// Montserrat is bundled as the closest open-source match to the Figma design's
/// "ProximaNova" (a paid font) -- see docs/DESIGN_GUIDE.md for the substitution
/// decision. Falls back to the system font if the named instance can't be loaded,
/// so a font-registration problem degrades gracefully instead of showing blank text.
enum AppFont {
    private static func postscriptName(for weight: UIFont.Weight) -> String {
        switch weight {
        case .regular:
            return "Montserrat-Regular"
        case .medium:
            return "Montserrat-Medium"
        case .semibold:
            return "Montserrat-SemiBold"
        case .bold:
            return "Montserrat-Bold"
        default:
            return "Montserrat-Regular"
        }
    }

    static func uiFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        UIFont(name: postscriptName(for: weight), size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    static func font(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        Font(uiFont(size: size, weight: weight))
    }
}
