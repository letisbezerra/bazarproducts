import UIKit
import Kingfisher

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.backgroundColor = ProductCell.brandColor
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        return label
    }()

    private let currentPriceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let originalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private static let brandColor = UIColor(red: 0.42, green: 0.11, blue: 0.32, alpha: 1)

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
        imageView.kf.setImage(with: product.imageURL, placeholder: UIImage(systemName: "photo"))
        currentPriceLabel.text = PriceFormatter.string(from: product.currentPrice)

        if let originalPrice = product.originalPrice, let discountPercentage = product.discountPercentage {
            badgeLabel.text = "\(discountPercentage)% off"
            badgeLabel.isHidden = false

            originalPriceLabel.attributedText = NSAttributedString(
                string: PriceFormatter.string(from: originalPrice),
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            originalPriceLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
            originalPriceLabel.isHidden = true
        }
    }

    private func setUpViews() {
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemBackground

        let priceStack = UIStackView(arrangedSubviews: [currentPriceLabel, originalPriceLabel])
        priceStack.axis = .horizontal
        priceStack.spacing = 6
        priceStack.alignment = .firstBaseline

        [imageView, badgeLabel, priceStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        badgeLabel.isHidden = true
        originalPriceLabel.isHidden = true

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: priceStack.topAnchor, constant: -8),

            badgeLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

            priceStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            priceStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),
            priceStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
    }
}
