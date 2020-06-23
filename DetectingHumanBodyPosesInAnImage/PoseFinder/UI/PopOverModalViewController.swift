/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details for the PopOverPresentationManager and
 PopOverPresentationController classes, both used to present the ConfigurationViewController's
 view to the user.
*/

import UIKit

// MARK: PopOverPresentationManager

class PopOverPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    var presentedViewController: UIViewController
    var presentingViewController: UIViewController

    init(presenting presentingViewController: UIViewController,
         presented presentedViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        self.presentedViewController = presentedViewController
    }

    // MARK: UIViewControllerTransitioningDelegate

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = PopOverPresentationController(presentedViewController: presented,
                                                                   presenting: presenting)
        return presentationController
    }
}

// MARK: - UIPresentationController

class PopOverPresentationController: UIPresentationController {
    /// Percentage used to compute the height of the view.
    private let popOverHeightRatio: CGFloat = 0.6

    override var frameOfPresentedViewInContainerView: CGRect {
        let viewHeight = containerView!.bounds.height * popOverHeightRatio
        let origin = CGPoint(x: 0, y: containerView!.bounds.height - viewHeight)
        let size = CGSize(width: containerView!.bounds.width,
                          height: viewHeight)
        return CGRect(origin: origin, size: size)
    }
}
