/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Scene Delegate.
*/
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        let coffeeListController = RBListViewController(viewModels: SampleData.viewModels())

        let svc = UISplitViewController()
        svc.maximumPrimaryColumnWidth = 450
        svc.preferredPrimaryColumnWidthFraction = 0.4
        svc.viewControllers = [
            RBNavigationController(rootViewController: coffeeListController)
        ]
        svc.preferredDisplayMode = .oneBesideSecondary

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = svc
        window?.makeKeyAndVisible()
    }

}

