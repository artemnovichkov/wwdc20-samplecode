/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class displays a list of previously placed orders.
*/

import UIKit
import SoupKit
import os.log

class OrderHistoryTableViewController: UITableViewController {
    
    private static let cellReuseIdentifier = "SoupOrderDetailCell"

    private enum SegueIdentifiers: String {
        case orderDetails = "Order Details"
        case soupMenu = "Soup Menu"
        case configureMenu = "Configure Menu"
    }
    
    private let soupMenuManager = SoupMenuManager()
    private let soupOrderManager = SoupOrderDataManager()
    private var notificationToken: NSObjectProtocol?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        return formatter
    }()
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationToken = NotificationCenter.default.addObserver(forName: dataChangedNotificationKey,
                                                                   object: soupOrderManager,
                                                                   queue: OperationQueue.main) {  [weak self] (notification) in
                                                                    self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    // MARK: - Target Action

    // This IBAction exposes a segue in the storyboard to unwind to this VC.
    @IBAction func unwindToOrderHistory(segue: UIStoryboardSegue) {}

    @IBAction func placeNewOrder(segue: UIStoryboardSegue) {
        if let source = segue.source as? OrderDetailViewController {
            soupOrderManager.placeOrder(order: source.order)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.orderDetails.rawValue {
            var order: Order? = nil
            
            if let activity = sender as? NSUserActivity,
                let orderID = activity.userInfo?[NSUserActivity.ActivityKeys.orderID.rawValue] as? UUID {
                
                // An order was completed outside of the app and then continued as a user activity in the app
                order = soupOrderManager.order(matching: orderID)
            } else if sender as? UITableViewCell != nil,
                let selectedIndexPaths = tableView.indexPathsForSelectedRows,
                let selectedIndexPath = selectedIndexPaths.first {
                
                // An order was completed inside the app
                order = soupOrderManager.orderHistory[selectedIndexPath.row]
            }
            
            if let destination = segue.destination as? OrderDetailViewController, let order = order {
                destination.configure(tableConfiguration: OrderDetailTableConfiguration(for: .historicalOrder), order: order)
            }
        } else if segue.identifier == SegueIdentifiers.configureMenu.rawValue {
            if let navController = segue.destination as? UINavigationController,
                let configureMenuTableViewController = navController.viewControllers.first as? ConfigureMenuTableViewController {
                configureMenuTableViewController.soupMenuManager = soupMenuManager
                configureMenuTableViewController.soupOrderDataManager = soupOrderManager
            }
        } else if segue.identifier == SegueIdentifiers.soupMenu.rawValue {
            if let navController = segue.destination as? UINavigationController,
                let menuController = navController.viewControllers.first as? SoupMenuViewController {
                
                if let activity = sender as? NSUserActivity, activity.activityType == NSStringFromClass(OrderSoupIntent.self) {
                    menuController.userActivity = activity
                } else {
                    menuController.userActivity = NSUserActivity.viewMenuActivity
                }
            }
        }
    }
    
    /// - Tag: continue_nsua
    /// This method is called when a user activity is continued via the restoration handler
    /// in `UIApplicationDelegate application(_:continue:restorationHandler:)`
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        if activity.activityType == NSUserActivity.viewMenuActivityType {
            driveContinueActivitySegue(SegueIdentifiers.soupMenu.rawValue, sender: nil)
            
        } else if activity.activityType == NSUserActivity.orderCompleteActivityType,
            (activity.userInfo?[NSUserActivity.ActivityKeys.orderID.rawValue] as? UUID) != nil {
            
            // Order complete, display the order history
            driveContinueActivitySegue(SegueIdentifiers.orderDetails.rawValue, sender: activity)
            
        } else if activity.activityType == NSStringFromClass(OrderSoupIntent.self) {
            // Order not completed, allow order to be customized
            driveContinueActivitySegue(SegueIdentifiers.soupMenu.rawValue, sender: activity)
        }
    }
    
    /// Ensures this view controller is visible by popping pushed order history, and dismissing anything presented modally before starting segue.
    private func driveContinueActivitySegue(_ segueID: String, sender: Any?) {
        let encapsulatedSegue = {
            self.performSegue(withIdentifier: segueID, sender: sender)
        }
        
        navigationController?.popToRootViewController(animated: false)
        if presentedViewController != nil {
            dismiss(animated: false, completion: {
                encapsulatedSegue()
            })
        } else {
            encapsulatedSegue()
        }
    }
}

extension OrderHistoryTableViewController {

    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soupOrderManager.orderHistory.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderHistoryTableViewController.cellReuseIdentifier, for: indexPath)
        let order = soupOrderManager.orderHistory[indexPath.row]
        cell.imageView?.image = UIImage(named: order.menuItem.iconImageName)
        cell.imageView?.applyRoundedCorners()
        
        cell.textLabel?.text = "\(order.quantity) \(order.menuItem.localizedName())"
        cell.detailTextLabel?.text = dateFormatter.string(from: order.date)
        return cell
    }
}
