/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that confirms an order was placed.
*/

import UIKit
import Intents
import SoupKit

class OrderConfirmedViewController: UIViewController {
    
    private let intent: OrderSoupIntent
    private let intentResponse: OrderSoupIntentResponse
    
    @IBOutlet var confirmationView: OrderConfirmedView!
    
    init(for soupIntent: OrderSoupIntent, with response: OrderSoupIntentResponse) {
        intent = soupIntent
        intentResponse = response
        super.init(nibName: "OrderConfirmedView", bundle: Bundle(for: OrderConfirmedViewController.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmationView = view as? OrderConfirmedView
        
        if let order = Order(from: intent) {
            confirmationView.itemNameLabel.text = order.menuItem.localizedName()
            confirmationView.imageView.applyRoundedCorners()
            if let orderDetails = intentResponse.orderDetails {
                confirmationView.timeLabel.text = orderDetails.displayString
            }
            confirmationView.imageView.image = UIImage(named: order.menuItem.iconImageName)
            switch order.orderType {
            case .unknown:
                confirmationView.infoLabel.text = ""
            case .delivery:
                if let deliveryLocation = order.deliveryLocation, let name = deliveryLocation.name {
                    confirmationView.infoLabel.text = "Deliver to \(name)"
                }
            case .pickup:
                if let storeLocation = order.storeLocation, let name = storeLocation.name {
                    confirmationView.infoLabel.text = "Pickup from \(name)"
                }
            }
        }
    }
}

class OrderConfirmedView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
}
