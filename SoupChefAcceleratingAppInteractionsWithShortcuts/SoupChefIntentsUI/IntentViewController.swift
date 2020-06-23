/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Create a custom user interface that shows in the Siri interface, as well as with 3D touches on a shortcut on the Cover Sheet or in Spotlight.
*/

import IntentsUI
import SoupKit

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    /// Prepare your view controller for displaying the details of the soup order.
    func configureView(for parameters: Set<INParameter>,
                       of interaction: INInteraction,
                       interactiveBehavior: INUIInteractiveBehavior,
                       context: INUIHostedViewContext,
                       completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        
        guard let intent = interaction.intent as? OrderSoupIntent else {
            completion(false, Set(), .zero)
            return
        }
        
        /*
         Different UIs can be displayed depending if the intent is in the confirmation phase or the handle phase.
         This example uses view controller containment to manage each of the different views via a dedicated view controller.
        */
        if interaction.intentHandlingStatus == .ready {
            let viewController = InvoiceViewController(for: intent)
            attachChild(viewController)
            completion(true, parameters, desiredSize)
        } else if interaction.intentHandlingStatus == .success {
            if let response = interaction.intentResponse as? OrderSoupIntentResponse {
                let viewController = OrderConfirmedViewController(for: intent, with: response)
                attachChild(viewController)
                completion(true, parameters, desiredSize)
            }
        }
        
        completion(false, parameters, .zero)
    }
    
    private var desiredSize: CGSize {
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        return CGSize(width: width, height: 120)
    }
    
    private func attachChild(_ viewController: UIViewController) {
        addChild(viewController)
        
        if let subview = viewController.view {
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false

            // Set the child controller's view to be the exact same size as the parent controller's view.
            subview.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            subview.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

            subview.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            subview.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        
        viewController.didMove(toParent: self)
    }
}
