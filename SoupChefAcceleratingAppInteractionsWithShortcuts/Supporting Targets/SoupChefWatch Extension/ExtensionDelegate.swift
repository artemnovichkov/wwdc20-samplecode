/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The watch extension delegate.
*/

import WatchKit
import SoupKitWatch

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func handle(_ userActivity: NSUserActivity) {
        guard let rootController = WKExtension.shared().rootInterfaceController else {
            return
        }
        
        rootController.popToRootController()
        
        if userActivity.activityType == NSStringFromClass(OrderSoupIntent.self),
            let intent = userActivity.interaction?.intent as? OrderSoupIntent {
            
            // This order can come from the "Chicken Noodle Soup" special menu item that is
            // donated to the system as a relevant shortcut on the Siri watch face.
            let order = Order(from: intent)
            rootController.pushController(withName: MenuInterfaceController.controllerIdentifier, context: order)
            
        } else if userActivity.activityType == NSUserActivity.viewMenuActivityType {
            
            rootController.pushController(withName: MenuInterfaceController.controllerIdentifier, context: nil)
        } else if userActivity.activityType == NSUserActivity.orderCompleteActivityType,
            (userActivity.userInfo?[NSUserActivity.ActivityKeys.orderID.rawValue] as? UUID) != nil {
                
            // Order complete, go to the order history interface
            rootController.pushController(withName: HistoryInterfaceController.controllerIdentifier, context: nil)
        }
    }
}
