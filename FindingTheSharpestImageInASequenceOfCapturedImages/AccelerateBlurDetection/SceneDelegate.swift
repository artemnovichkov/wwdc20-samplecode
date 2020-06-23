/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of SceneDelegate that demonstrates image sharpness detection.
*/

import UIKit
import SwiftUI

struct BlurDetectorKey: EnvironmentKey {
    static var defaultValue: BlurDetector {
        BlurDetector()
    }
}

extension EnvironmentValues {
    var blurDetector: BlurDetector {
        get { self[BlurDetectorKey.self] }
        set { self[BlurDetectorKey.self] = newValue }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let model = BlurDetectorResultModel()
    let blurDetector = BlurDetector()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)

            window.rootViewController = UIHostingController(rootView: BlurDetectorView()
                .environmentObject(model)
                .environment(\.blurDetector, blurDetector))

            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

