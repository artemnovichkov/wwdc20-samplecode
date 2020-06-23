/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `WKInterfaceController` that displays confirmation an order was placed successfully.
*/

import WatchKit
import Foundation
import SoupKitWatch

/// Displays confirmation after placing an order.
class OrderConfirmedInterfaceController: WKInterfaceController {

    static let controllerIdentifier = "orderComplete"
    
    @IBOutlet var image: WKInterfaceImage!
    
    override func awake(withContext context: Any?) {
        guard let order = context as? Order else { return }
        image.setImage(UIImage(named: order.menuItem.iconImageName))
        
        /*
         Placing an order on the watch uses the same code as in the iOS app. This means the order
         will be turned into an INInteraction, and donated to the system. The interaction object
         is marked eligible for prediction, and may show up on the Siri Watch Face at appropiate times
         in the future.
         */
        let orderManager = SoupOrderDataManager()
        orderManager.placeOrder(order: order)
    }
}
