import UIKit

/// UILabel has no equivalent to UIButton's contentEdgeInsets -- without this, a label
/// used as a filled pill (e.g. the discount badge) only ever "looks" padded when its
/// text happens to be smaller than an arbitrary minimum-width constraint. Real, fixed
/// insets keep the padding correct at any text size, including with Dynamic Type.
final class InsetLabel: UILabel {
    var textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
