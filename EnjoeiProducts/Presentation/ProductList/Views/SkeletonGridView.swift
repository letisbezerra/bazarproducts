import UIKit

final class SkeletonGridView: UIView {
    private static let rows = 4
    private static let columns = 2
    private static let spacing: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = Self.spacing
        verticalStack.distribution = .fillEqually
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(verticalStack)

        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for _ in 0..<Self.rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Self.spacing
            rowStack.distribution = .fillEqually

            for _ in 0..<Self.columns {
                let block = UIView()
                block.backgroundColor = .systemGray6
                block.layer.cornerRadius = 12
                rowStack.addArrangedSubview(block)
            }

            verticalStack.addArrangedSubview(rowStack)
        }
    }
}

#if DEBUG
import SwiftUI

private struct SkeletonGridViewPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> SkeletonGridView {
        SkeletonGridView()
    }

    func updateUIView(_ uiView: SkeletonGridView, context: Context) {}
}

#Preview {
    SkeletonGridViewPreview()
        .frame(width: 360, height: 950)
}
#endif
