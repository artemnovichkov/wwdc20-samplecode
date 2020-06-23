/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that lists the order invoice.
*/

import UIKit
import SoupKit

class InvoiceViewController: UIViewController {
    
    private let intent: OrderSoupIntent
    
    @IBOutlet weak var invoiceView: InvoiceView!
    
    init(for soupIntent: OrderSoupIntent) {
        intent = soupIntent
        super.init(nibName: "InvoiceView", bundle: Bundle(for: InvoiceViewController.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let order = Order(from: intent) {
            invoiceView.itemNameLabel.text = order.menuItem.localizedName()
            invoiceView.imageView.applyRoundedCorners()
            invoiceView.totalPriceLabel.text = order.localizedCurrencyValue
            invoiceView.unitPriceLabel.text = "\(order.quantity) @ \(order.menuItem.localizedCurrencyValue)"
            invoiceView.imageView.image = UIImage(named: order.menuItem.iconImageName)
            switch order.orderType {
            case .unknown:
                invoiceView.infoLabel.text = ""
            case .delivery:
                if let deliveryLocation = order.deliveryLocation, let name = deliveryLocation.name {
                    invoiceView.infoLabel.text = "Deliver to \(name)"
                }
            case .pickup:
                if let storeLocation = order.storeLocation, let name = storeLocation.name {
                    invoiceView.infoLabel.text = "Pickup from \(name)"
                }
            }
            
            let flattenedToppings = order.menuItemToppings.map { (topping) -> String in
                return topping.rawValue
            }.joined(separator: ", ")
            
            invoiceView.toppingsLabel.text = flattenedToppings
        }
    }
}

class InvoiceView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var unitPriceLabel: UILabel!
    @IBOutlet weak var toppingsLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
}
