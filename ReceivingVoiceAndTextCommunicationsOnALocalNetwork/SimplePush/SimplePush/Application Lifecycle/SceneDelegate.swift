/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A delegate that presents the main `RootView` of the app and loads the `DirectoryView` inside of the root.
*/

import UIKit
import SwiftUI
import Combine
import SimplePushKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let rootViewModel = RootViewModel()
    private let directoryViewModel = DirectoryViewModel()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let view = RootView(viewModel: rootViewModel) {
            DirectoryView(rootViewModel: self.rootViewModel, viewModel: self.directoryViewModel)
        }
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: view)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
