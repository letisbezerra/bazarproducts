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

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "buscar"
        searchBar.showsCancelButton = false
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    private let clearSearchButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "limpar busca"
        configuration.baseForegroundColor = UIColor(named: "BrandPurple")
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
        configuration.baseBackgroundColor = UIColor(named: "BrandPurple")
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
        title = "Favoritos"

        setUpViews()

        viewModel.onChange = { [weak self] in
            self?.render()
        }

        Task {
            await viewModel.loadInitialPage()
        }
    }

    private func setUpViews() {
        searchBar.delegate = self
        clearSearchButton.addTarget(self, action: #selector(clearSearchTapped), for: .touchUpInside)

        addChild(emptyStateHostingController)
        emptyStateHostingController.didMove(toParent: self)

        let searchRow = UIStackView(arrangedSubviews: [searchBar, clearSearchButton])
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

            collectionView.topAnchor.constraint(equalTo: searchRow.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: paginationIndicator.topAnchor, constant: -8),

            skeletonView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),

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
        clearSearchButton.isHidden = viewModel.searchText.isEmpty

        if viewModel.isLoadingNextPage {
            paginationIndicator.startAnimating()
        } else {
            paginationIndicator.stopAnimating()
        }

        switch viewModel.state {
        case .loading:
            skeletonView.isHidden = false
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyStateHostingController.view.isHidden = true

        case .loaded:
            skeletonView.isHidden = true
            errorView.isHidden = true
            let showsEmptyState = viewModel.showsNoResultsState
            emptyStateHostingController.view.isHidden = !showsEmptyState
            collectionView.isHidden = showsEmptyState
            applySnapshot()

        case .error(let message):
            skeletonView.isHidden = true
            collectionView.isHidden = true
            emptyStateHostingController.view.isHidden = true
            errorView.isHidden = false
            errorLabel.text = message
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.displayedProducts)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func clearSearch() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        viewModel.clearSearch()
    }

    @objc
    private func clearSearchTapped() {
        clearSearch()
    }

    @objc
    private func retryTapped() {
        Task { await viewModel.loadInitialPage() }
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

extension ProductListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.updateSearchText(searchText)
        clearSearchButton.isHidden = searchText.isEmpty
    }
}
