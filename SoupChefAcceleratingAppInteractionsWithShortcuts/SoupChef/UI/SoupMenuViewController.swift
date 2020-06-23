/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller displays the list of active menu items to the user.
*/

import UIKit
import SoupKit
import os.log

class SoupMenuViewController: UITableViewController {
    
    private static let cellReuseIdentifier = "SoupMenuItemDetailCell"
    
    private enum SegueIdentifiers: String {
        case newOrder = "Show New Order Detail Segue"
    }
    
    private var menuItems: [MenuItem] = SoupMenuManager().findItems(exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem])
    
    override var userActivity: NSUserActivity? {
        didSet {
            if userActivity?.activityType == NSStringFromClass(OrderSoupIntent.self) {
                performSegue(withIdentifier: SegueIdentifiers.newOrder.rawValue, sender: userActivity)
            }
        }
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.newOrder.rawValue {
            guard let destination = segue.destination as? OrderDetailViewController else { return }
            
            var order: Order?
            
            if sender as? UITableViewCell? != nil,
                let indexPath = tableView.indexPathForSelectedRow {
                order = Order(quantity: 1, menuItem: menuItems[indexPath.row], menuItemToppings: [])
            } else if let activity = sender as? NSUserActivity,
                let orderIntent = activity.interaction?.intent as? OrderSoupIntent {
                order = Order(from: orderIntent)
            }
            
            if let order = order {
                // Pass the represented menu item to OrderDetailTableConfiguration.
                let orderType = OrderDetailTableConfiguration(for: .newOrder)
                destination.configure(tableConfiguration: orderType, order: order)
            }
        }
    }
}

extension SoupMenuViewController {
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SoupMenuViewController.cellReuseIdentifier, for: indexPath)
        let menuItem = menuItems[indexPath.row]
        cell.imageView?.image = UIImage(named: menuItem.iconImageName)
        cell.imageView?.applyRoundedCorners()
        cell.textLabel?.text = menuItems[indexPath.row].localizedName()
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
