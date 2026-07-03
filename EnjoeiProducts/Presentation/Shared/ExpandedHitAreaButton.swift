import UIKit

/// Expands only the tappable area, not the visual frame, so a button can stay
/// visually compact (matching a Figma measurement) while still meeting the
/// HIG's 44x44pt minimum tap target. Shared (not scoped to one screen) so any
/// small button elsewhere can reach for the same, tested mechanism instead of
/// re-inventing a one-off fix.
final class ExpandedHitAreaButton: UIButton {
    private static let minimumHitAreaSize: CGFloat = 44

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let widthInset = min(0, bounds.width - Self.minimumHitAreaSize) / 2
        let heightInset = min(0, bounds.height - Self.minimumHitAreaSize) / 2
        return bounds.insetBy(dx: widthInset, dy: heightInset).contains(point)
    }
}
