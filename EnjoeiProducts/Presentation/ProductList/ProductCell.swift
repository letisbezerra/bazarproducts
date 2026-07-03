import UIKit
import Kingfisher

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"

    // The card renders at roughly 163pt square (see makeLayout's comment in
    // ProductListViewController); downsampling to a fixed bound well above that
    // avoids decoding/caching each photo at its full network resolution.
    private static let imageProcessor = DownsamplingImageProcessor(
        size: CGSize(width: 200 * UIScreen.main.scale, height: 200 * UIScreen.main.scale)
    )

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Solid background instead of an icon placeholder: an SF Symbol under
        // scaleAspectFill stretches into an unrecognizable shape at this size.
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.uiFont(size: 10, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = BrandColor.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        return label
    }()

    private let priceContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()

    private let currentPriceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.uiFont(size: 12, weight: .regular)
        return label
    }()

    private let originalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.uiFont(size: 12, weight: .regular)
        label.textColor = ReadableGray.uiColor
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        badgeLabel.isHidden = true
        originalPriceLabel.isHidden = true
        originalPriceLabel.attributedText = nil
    }

    func configure(with product: Product) {
        imageView.kf.setImage(with: product.imageURL, options: [.processor(Self.imageProcessor)])
        let currentPriceText = PriceFormatter.string(from: product.currentPrice)
        currentPriceLabel.text = currentPriceText
        isAccessibilityElement = true

        if let originalPrice = product.originalPrice, let discountPercentage = product.discountPercentage {
            let originalPriceText = PriceFormatter.string(from: originalPrice)
            badgeLabel.text = "\(discountPercentage)% off"
            badgeLabel.isHidden = false

            currentPriceLabel.textColor = BrandColor.uiColor
            originalPriceLabel.attributedText = NSAttributedString(
                string: originalPriceText,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: ReadableGray.uiColor
                ]
            )
            originalPriceLabel.isHidden = false

            accessibilityLabel = "\(product.title), \(currentPriceText), "
                + "de \(originalPriceText), \(discountPercentage)% off"
        } else {
            badgeLabel.isHidden = true
            originalPriceLabel.isHidden = true
            currentPriceLabel.textColor = .label

            accessibilityLabel = "\(product.title), \(currentPriceText)"
        }
    }

    private func setUpViews() {
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        let priceStack = UIStackView(arrangedSubviews: [currentPriceLabel, originalPriceLabel])
        priceStack.axis = .horizontal
        priceStack.spacing = 6
        priceStack.alignment = .firstBaseline
        priceStack.translatesAutoresizingMaskIntoConstraints = false
        priceContainerView.addSubview(priceStack)

        [imageView, badgeLabel, priceContainerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        badgeLabel.isHidden = true
        originalPriceLabel.isHidden = true

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            badgeLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            badgeLabel.heightAnchor.constraint(equalToConstant: 22),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

            priceContainerView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            priceContainerView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            priceContainerView.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -8),

            priceStack.topAnchor.constraint(equalTo: priceContainerView.topAnchor, constant: 4),
            priceStack.bottomAnchor.constraint(equalTo: priceContainerView.bottomAnchor, constant: -4),
            priceStack.leadingAnchor.constraint(equalTo: priceContainerView.leadingAnchor, constant: 8),
            priceStack.trailingAnchor.constraint(equalTo: priceContainerView.trailingAnchor, constant: -8)
        ])

        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
    }
}

#if DEBUG
import SwiftUI

private struct ProductCellPreview: UIViewRepresentable {
    let product: Product

    func makeUIView(context: Context) -> ProductCell {
        let cell = ProductCell(frame: CGRect(x: 0, y: 0, width: 163, height: 163))
        cell.configure(with: product)
        return cell
    }

    func updateUIView(_ uiView: ProductCell, context: Context) {}
}

#Preview("With discount") {
    ProductCellPreview(product: Product(
        id: 1,
        title: "vestido azul",
        imageURL: nil,
        currentPrice: 56.0,
        originalPrice: 80.0,
        discountPercentage: 30
    ))
    .frame(width: 163, height: 163)
}

#Preview("Without discount") {
    ProductCellPreview(product: Product(
        id: 2,
        title: "sapato preto",
        imageURL: nil,
        currentPrice: 234.0,
        originalPrice: nil,
        discountPercentage: nil
    ))
    .frame(width: 163, height: 163)
}
#endif
