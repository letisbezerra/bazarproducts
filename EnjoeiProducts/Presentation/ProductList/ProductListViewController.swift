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
        collectionView.accessibilityIdentifier = "productCollectionView"
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
        textField.font = AppFont.uiFont(size: 15, weight: .regular, textStyle: .subheadline)
        textField.adjustsFontForContentSizeCategory = true
        // searchField/searchRow are pinned to a hard, Figma-measured 42pt height below (not a
        // fitting/minimum height), so this field's text can't be allowed to scale as far as
        // the badge/price labels (which live in a taller, more forgiving layout) without
        // clipping inside that fixed box.
        textField.maximumContentSizeCategory = .extraExtraExtraLarge
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1.5
        textField.layer.borderColor = HeaderDividerColor.uiColor.cgColor
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
        let button = ExpandedHitAreaButton(configuration: configuration)
        button.isHidden = true
        button.accessibilityIdentifier = "inlineClearSearchButton"
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
        label.textColor = ReadableGray.uiColor
        return label
    }()

    private lazy var retryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "tentar novamente"
        configuration.baseBackgroundColor = BrandColor.uiColor
        // HIG minimum tap target is 44x44pt; the default filled-button insets
        // don't reach that height on their own.
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 24, bottom: 13, trailing: 24)
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

    // VoiceOver never announces a screen's dynamic changes on its own -- without explicitly
    // posting these, a loading/search/no-results transition is completely silent unless the
    // user happens to already be swiped onto the element that changed. These two track what
    // was last announced so render() (called on every viewModel.onChange, including
    // pagination) only posts on an actual transition, not on every re-render.
    private var previousState: ProductListViewModel.State?
    private var previousAnnouncedSearchText: String?
    private lazy var logoButton = makeLogoView()

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
        navigationItem.titleView = logoButton
        configureNavigationBarDivider()

        setUpViews()

        viewModel.onChange = { [weak self] in
            self?.render()
        }

        Task {
            await viewModel.loadInitialPage()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // A post from render()/setUpViews() during viewDidLoad happens before the view is
        // actually on screen and can be silently dropped by VoiceOver -- viewDidAppear is
        // Apple's documented safe point for a screen's first announcement. Guarded to the
        // still-loading case so this never double-announces if the fetch already finished.
        if viewModel.state == .loading {
            UIAccessibility.post(notification: .announcement, argument: "Carregando produtos")
        }
    }

    private func render() {
        let stateChanged = viewModel.state != previousState
        defer { previousState = viewModel.state }

        switch viewModel.state {
        case .loading:
            skeletonView.isHidden = false
            collectionView.isHidden = true
            errorView.isHidden = true
            emptyStateHostingController.view.isHidden = true
            paginationIndicator.stopAnimating()

            // previousState == nil is the very first render (during viewDidLoad, before the
            // view is on screen) -- that announcement is handled by viewDidAppear instead,
            // since a post this early can be silently dropped. This branch only fires for a
            // later retry, when the screen is already visible.
            if stateChanged, previousState != nil {
                UIAccessibility.post(notification: .announcement, argument: "Carregando produtos")
            }

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

            if stateChanged {
                // .screenChanged is meant for an actual new screen/view controller appearing;
                // this is the same screen with its content updated, which is exactly what
                // .layoutChanged (not .screenChanged) is documented for -- redirecting VoiceOver
                // focus to a specific already-on-screen element without treating it as
                // navigation. A nil argument also left VoiceOver to guess the target, which in
                // practice landed outside this screen entirely (e.g. the status bar).
                UIAccessibility.post(notification: .layoutChanged, argument: logoButton)
            } else if viewModel.searchText != previousAnnouncedSearchText {
                announceSearchResult(showsEmptyState: showsEmptyState)
            }
            previousAnnouncedSearchText = viewModel.searchText

        case .error(let message):
            skeletonView.isHidden = true
            collectionView.isHidden = true
            emptyStateHostingController.view.isHidden = true
            errorView.isHidden = false
            errorLabel.text = message
            paginationIndicator.stopAnimating()

            if stateChanged {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    private func announceSearchResult(showsEmptyState: Bool) {
        guard !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let announcement = showsEmptyState
            ? "Nenhum produto encontrado para \(viewModel.searchText)"
            : "\(viewModel.displayedProducts.count) produtos encontrados"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func updateClearSearchButtonVisibility() {
        clearSearchButton.isHidden = (searchField.text ?? "").isEmpty
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.displayedProducts)
        dataSource.apply(snapshot, animatingDifferences: true)
        // Test-only signal, gated behind a launch argument so it's never set for a real
        // user (accessibilityValue is read aloud by VoiceOver -- a raw item count would be
        // a confusing announcement). UICollectionView recycles off-screen cells, so
        // collectionView.cells.count (what XCUITest can otherwise observe) never reflects
        // the true number of loaded items, only however many currently fit on screen.
        if UITestingFlag.exposesLoadedItemCount.isEnabled {
            collectionView.accessibilityValue = "\(viewModel.displayedProducts.count)"
        }
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
    private func logoTapped() {
        clearSearch()
        collectionView.setContentOffset(.zero, animated: true)
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
}

// MARK: - View setup

private extension ProductListViewController {
    /// Figma measures the header bar's bottom border as 1.5px `#F1EEEC` -- the system
    /// nav bar's default hairline is a different gray, so it's recolored here to match.
    func configureNavigationBarDivider() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = HeaderDividerColor.uiColor

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    // A button (not a plain UIImageView) so tapping the logo to reset the screen works
    // identically for a sighted tap and for a VoiceOver double-tap -- one mechanism for both,
    // instead of bolting a gesture recognizer onto an image. ExpandedHitAreaButton widens the
    // tappable area to HIG's 44x44pt minimum without growing the logo past its 32x32 visual size.
    func makeLogoView() -> ExpandedHitAreaButton {
        // UIButton.Configuration.plain() with only an image set rendered a stray artifact
        // (a thin line through the logo) -- likely the configuration system still allocating
        // layout for an empty title. The classic .custom + setImage(_:for:) API has no such
        // title-layout behavior and renders identically to the original plain UIImageView.
        let button = ExpandedHitAreaButton(type: .custom)
        button.setImage(UIImage(named: "EnjoeiLogo"), for: .normal)
        // Without explicit fill alignment, UIButton sizes its imageView to the image's own
        // intrinsic (likely @3x, much larger than 32x32) size and centers it, rather than
        // scaling to the button's bounds -- cropping most of the logo to a tiny sliver.
        // .fill alignment makes the imageView span the button's content area first, so
        // .scaleAspectFit then has the right frame to scale within.
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.imageView?.contentMode = .scaleAspectFit
        // Folded into the label itself (not just accessibilityHint) since VoiceOver's "speak
        // hints" is a setting some users disable -- a label-only description guarantees a
        // user landing here from the search field still understands this is the way back,
        // instead of relying on a hint that might never be spoken.
        button.accessibilityLabel = "Enjoei, início"
        button.addTarget(self, action: #selector(logoTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        return button
    }

    func setUpViews() {
        // A plain UIView with no accessible descendants isn't reliably surfaced in the
        // accessibility tree just by having an identifier -- without this, ProductListUITests'
        // query for it was flaky (present in the automation snapshot on some runs, absent on
        // others). Marking it an element directly makes it unambiguous, and giving it a real
        // label (rather than leaving it silent) also fixes a genuine VoiceOver gap: without
        // one, a VoiceOver user swiping through the loading screen would land on an unlabeled
        // stop instead of hearing that content is loading.
        skeletonView.isAccessibilityElement = true
        skeletonView.accessibilityLabel = "Carregando produtos"
        skeletonView.accessibilityIdentifier = "skeletonGridView"
        // .editingChanged doesn't reliably fire for dictated text (it's inserted through a
        // different path than character-by-character typing) -- textDidChangeNotification
        // fires for any text change regardless of input method (typing, dictation, paste).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchFieldDidChange),
            name: UITextField.textDidChangeNotification,
            object: searchField
        )
        searchField.delegate = self
        clearSearchButton.addTarget(self, action: #selector(clearSearchTapped), for: .touchUpInside)

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)

        addChild(emptyStateHostingController)

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

        // UIKit's documented child-view-controller order: add the view to the
        // hierarchy *then* call didMove(toParent:), not before.
        emptyStateHostingController.didMove(toParent: self)

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

    /// Each card is square (matches the Figma measurement of a 163x163 tile at the
    /// reference frame width) -- computed from the actual available width via
    /// `sectionProvider` instead of hardcoding 163pt, so it scales on other screen sizes.
    static func makeLayout() -> UICollectionViewCompositionalLayout {
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

extension ProductListViewController: UITextFieldDelegate {
    // Nothing previously handled the keyboard's "buscar" return key -- it just sat there with
    // no effect. Dismissing the keyboard here leaves the search field itself as the last
    // focused element, so swiping from it (with VoiceOver, or otherwise continuing to use the
    // screen) naturally reaches the next element (e.g. "limpar busca") instead of leaving the
    // keyboard up indefinitely.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

#if DEBUG
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
