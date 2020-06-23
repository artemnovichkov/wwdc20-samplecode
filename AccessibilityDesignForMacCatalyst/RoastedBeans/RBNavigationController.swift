/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Navigation Controller.
*/
import UIKit

final class RBNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.tintColor = .brown
        navigationBar.titleTextAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .headline).bold()
        ]
    }
}

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0)
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}
