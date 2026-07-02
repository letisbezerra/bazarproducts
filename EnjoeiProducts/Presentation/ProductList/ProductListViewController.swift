import SwiftUI
import UIKit

final class ProductListViewController: UIViewController {
    private nonisolated enum Section: Hashable {
        case main
    }

    private static let interItemSpacing: CGFloat = 8

    private let viewModel: ProductListViewModel

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        return collectionView
    }()

    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, Product>(
        collectionView: collectionView
    ) { collectionView, indexPath, product in
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProductCell.reuseIdentifier,
            for: indexPath
        ) as? ProductCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: product)
        return cell
    }

    // A plain UITextField instead of UISearchBar: UISearchBar's `.minimal` style
    // reasserts its own capsule-shaped background and left-side icon internally,
    // fighting any attempt to match Figma's near-rectangular box with a trailing icon.
    private let searchField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "buscar"
        textField.font = AppFont.uiFont(size: 15, weight: .regular)
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(named: "HeaderDivider")?.cgColor
        textField.returnKeyType = .search
        textField.clearButtonMode = .never
        textField.enablesReturnKeyAutomatically = false

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.leftView = leftPadding
        textField.leftViewMode = .always

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 20))
        searchIcon.frame = CGRect(x: 0, y: 2, width: 16, height: 16)
        rightContainer.addSubview(searchIcon)
        textField.rightView = rightContainer
        textField.rightViewMode = .always

        return textField
    }()

    private let clearSearchButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "limpar busca"
        configuration.baseForegroundColor = BrandColor.uiColor
        let button = UIButton(configuration: configuration)
        button.isHidden = true
        return button
    }()

    private let skeletonView = SkeletonGridView()

    private let paginationIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var retryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "tentar novamente"
        configuration.baseBackgroundColor = BrandColor.uiColor
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    private lazy var errorView: UIView = {
        let stack = UIStackView(arrangedSubviews: [errorLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private lazy var emptyStateHostingController = UIHostingController(
        rootView: EmptyStateView(onClearSearch: { [weak self] in self?.clearSearch() })
    )

    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.titleView = makeLogoView()
        configureNavigationBarDivider()

        setUpViews()

        viewModel.onChange = { [weak self] in
            self?.render()
        }

        Task {
            await viewModel.loadInitialPage()
        }
    }

    /// Figma measures the header bar's bottom border as 1.5px `#F1EEEC` -- the system
    /// nav bar's default hairline is a different gray, so it's recolored here to match.
    private func configureNavigationBarDivider() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor(named: "HeaderDivider")

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func makeLogoView() -> UIImageView {
        let logoImageView = UIImageView(image: UIImage(named: "EnjoeiLogo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.isAccessibilityElement = true
        logoImageView.accessibilityLabel = "Enjoei"
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 32),
            logoImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
        return logoImageView
    }

    private func setUpViews() {
        searchField.addTarget(self, action: #selector(searchFieldDidChange), for: .editingChanged)
        clearSearchButton.addTarget(self, action: #selector(clearSearchTapped), for: .touchUpInside)

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)

        addChild(emptyStateHostingController)
        emptyStateHostingController.didMove(toParent: self)

        let searchRow = UIStackView(arrangedSubviews: [searchField, clearSearchButton])
        searchRow.axis = .horizontal
        searchRow.alignment = .center
        searchRow.spacing = 8

        [
            searchRow, collectionView, skeletonView, errorView,
            emptyStateHostingController.view, paginationIndicator
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            searchRow.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Neither searchRow nor collectionView has both edges pinned independently of
            // the other, so without an explicit height here Auto Layout treats searchRow's
            // height as a free variable and can inflate it arbitrarily to satisfy the rest
            // of the chain -- pin it to Figma's measured 335x42 search box.
            searchRow.heightAnchor.constraint(equalToConstant: 42),
            searchField.heightAnchor.constraint(equalToConstant: 42),

            collectionView.topAnchor.constraint(equalTo: searchRow.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: paginationIndicator.topAnchor, constant: -8),

            skeletonView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),

            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            errorView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            emptyStateHostingController.view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyStateHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            paginationIndicator.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
            paginationIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        render()
    }

    private func render() {
        switch viewModel.state {
        case .loading:
            skeletonView.isHidden = false
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyStateHostingController.view.isHidden = true
            paginationIndicator.stopAnimating()

        case .loaded:
            skeletonView.isHidden = true
            errorView.isHidden = true
            let showsEmptyState = viewModel.showsNoResultsState
            emptyStateHostingController.view.isHidden = !showsEmptyState
            collectionView.isHidden = showsEmptyState
            applySnapshot()

            if viewModel.isLoadingNextPage && !showsEmptyState {
                paginationIndicator.startAnimating()
            } else {
                paginationIndicator.stopAnimating()
            }

        case .error(let message):
            skeletonView.isHidden = true
            collectionView.isHidden = true
            emptyStateHostingController.view.isHidden = true
            errorView.isHidden = false
            errorLabel.text = message
            paginationIndicator.stopAnimating()
        }
    }

    private func updateClearSearchButtonVisibility() {
        clearSearchButton.isHidden = (searchField.text ?? "").isEmpty
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.displayedProducts)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func clearSearch() {
        searchField.text = ""
        searchField.resignFirstResponder()
        viewModel.clearSearch()
        updateClearSearchButtonVisibility()
    }

    @objc
    private func clearSearchTapped() {
        clearSearch()
    }

    @objc
    private func searchFieldDidChange() {
        let text = searchField.text ?? ""
        viewModel.updateSearchText(text)
        updateClearSearchButtonVisibility()
    }

    @objc
    private func retryTapped() {
        Task { await viewModel.loadInitialPage() }
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Each card is square (matches the Figma measurement of a 163x163 tile at the
    /// reference frame width) -- computed from the actual available width via
    /// `sectionProvider` instead of hardcoding 163pt, so it scales on other screen sizes.
    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns = 2
            let containerWidth = environment.container.effectiveContentSize.width
            let itemWidth = (containerWidth - interItemSpacing * CGFloat(columns - 1)) / CGFloat(columns)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemWidth)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            group.interItemSpacing = .fixed(interItemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = interItemSpacing
            return section
        }
    }
}

extension ProductListViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let maxRow = indexPaths.map(\.item).max() else { return }
        viewModel.loadNextPageIfNeeded(currentRow: maxRow)
    }
}

extension ProductListViewController: UICollectionViewDelegate {}

extension ProductListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view?.isDescendant(of: searchField) ?? false)
    }
}

#if DEBUG
import SwiftUI

private struct PreviewFetchLikedProductsUseCase: FetchLikedProductsUseCase {
    func execute(page: Int) async throws -> ProductsPage {
        let items = (1...10).map { index in
            Product(
                id: index,
                title: "produto \(index)",
                imageURL: nil,
                currentPrice: 56.0,
                originalPrice: index.isMultiple(of: 2) ? 80.0 : nil,
                discountPercentage: index.isMultiple(of: 2) ? 30 : nil
            )
        }
        return ProductsPage(items: items, hasNextPage: false)
    }
}

private struct ProductListViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ProductListViewController(
            viewModel: ProductListViewModel(useCase: PreviewFetchLikedProductsUseCase())
        )
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview("Results") {
    ProductListViewControllerPreview()
}
#endif
