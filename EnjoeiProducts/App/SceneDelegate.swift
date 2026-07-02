import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let httpClient = URLSessionHTTPClient()
        let repository = ProductsRepositoryImpl(httpClient: httpClient)
        let useCase = DefaultFetchLikedProductsUseCase(repository: repository)
        let viewModel = ProductListViewModel(useCase: useCase)
        let productListViewController = ProductListViewController(viewModel: viewModel)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: productListViewController)
        window.makeKeyAndVisible()
        self.window = window
    }
}
