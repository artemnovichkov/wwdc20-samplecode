/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class shows soup order details. It can be configured for two possible order types.
 When configured with a 'new' order type, the view controller collects details of a new order.
 When configured with a 'historical' order type, the view controller displays details of a previously placed order.
*/

import UIKit
import SoupKit
import os.log
import IntentsUI

class OrderDetailViewController: UITableViewController {
    
    private(set) var order: Order!
    
    private var tableConfiguration: OrderDetailTableConfiguration = OrderDetailTableConfiguration(for: .newOrder)
    
    private weak var quantityLabel: UILabel?
    
    private weak var totalLabel: UILabel?
    
    private var toppingMap: [String: String] = [:]
    
    @IBOutlet var tableViewHeader: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet var tableFooterView: UIView!
    
    // MARK: - Setup Order Detail View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if tableConfiguration.purpose == .historicalOrder {
            navigationItem.rightBarButtonItem = nil
        }
        configureTableViewHeader()
        configureTableFooterView()
    }
    
    private func configureTableViewHeader() {
        headerImageView.image = UIImage(named: order.menuItem.iconImageName)
        headerImageView.applyRoundedCorners()
        headerLabel.text = order.menuItem.localizedName()
        tableView.tableHeaderView = tableViewHeader
    }
    
    /// - Tag: add_to_siri_button
    private func configureTableFooterView() {
        if tableConfiguration.purpose == .historicalOrder {
            let addShortcutButton = INUIAddVoiceShortcutButton(style: .automaticOutline)
            addShortcutButton.shortcut = INShortcut(intent: order.intent)
            addShortcutButton.delegate = self
            
            addShortcutButton.translatesAutoresizingMaskIntoConstraints = false
            tableFooterView.addSubview(addShortcutButton)
            tableFooterView.centerXAnchor.constraint(equalTo: addShortcutButton.centerXAnchor).isActive = true
            tableFooterView.centerYAnchor.constraint(equalTo: addShortcutButton.centerYAnchor).isActive = true
            
            tableView.tableFooterView = tableFooterView
        }
    }
    
    func configure(tableConfiguration: OrderDetailTableConfiguration, order: Order) {
        self.tableConfiguration = tableConfiguration
        self.order = order
    }
    
    // MARK: - Target Action
    
    @IBAction private func placeOrder(_ sender: UIBarButtonItem) {
        if order.quantity == 0 {
            os_log("Quantity must be greater than 0 to add to order")
            return
        }
        performSegue(withIdentifier: "Place Order Segue", sender: self)
    }
    
    @IBAction private func stepperDidChange(_ sender: UIStepper) {
        order.quantity = Int(sender.value)
        quantityLabel?.text = "\(order.quantity)"
        updateTotalLabel()
    }
    
    private func updateTotalLabel() {
        totalLabel?.text = order.localizedCurrencyValue
    }
}

extension OrderDetailViewController {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableConfiguration.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableConfiguration.sections[section].rowCount
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableConfiguration.sections[section].type.rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionModel = tableConfiguration.sections[indexPath.section]
        let reuseIdentifier = sectionModel.cellReuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configure(cell: cell, at: indexPath, with: sectionModel)
        return cell
    }
    
    private func configure(cell: UITableViewCell, at indexPath: IndexPath, with sectionModel: OrderDetailTableConfiguration.SectionModel) {
        switch sectionModel.type {
        case .price:
            cell.textLabel?.text = NumberFormatter.currencyFormatter.string(from: (order.menuItem.price as NSDecimalNumber))
        case .quantity:
            if let cell = cell as? QuantityTableViewCell {
                if tableConfiguration.purpose == .newOrder {
                    // Save a weak reference to the quantityLabel for quick udpates, later.
                    quantityLabel = cell.quantityLabel
                    cell.stepper.addTarget(self, action: #selector(OrderDetailViewController.stepperDidChange(_:)), for: .valueChanged)
                } else {
                    cell.quantityLabel.text = "\(order.quantity)"
                    cell.stepper.isHidden = true
                }
            }
        case .toppings:
            /*
             Maintain a mapping of [rawValue: localizedValue] in order to help instanitate Order.MenuItemTopping enum
             later when a topping is selected in the table view.
             */
            let topping = Order.MenuItemTopping.allCases[indexPath.row]
            let localizedValue = topping.rawValue
            toppingMap[localizedValue] = topping.rawValue
            
            cell.textLabel?.text = localizedValue
            cell.accessoryType = order.menuItemToppings.contains(topping) ? .checkmark : .none
            
        case .total:
            //  Save a weak reference to the totalLabel for making quick updates later.
            totalLabel = cell.textLabel
            
            updateTotalLabel()
        }
    }
}

extension OrderDetailViewController {
    
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableConfiguration.sections[indexPath.section].type == .toppings && tableConfiguration.purpose == .newOrder {
            
            guard let cell = tableView.cellForRow(at: indexPath),
                let cellText = cell.textLabel?.text,
                let toppingRawValue = toppingMap[cellText],
                let topping = Order.MenuItemTopping(rawValue: toppingRawValue) else { return }
            
            if order.menuItemToppings.contains(topping) {
                order.menuItemToppings.remove(topping)
                cell.accessoryType = .none
            } else {
                order.menuItemToppings.insert(topping)
                cell.accessoryType = .checkmark
            }
        }
    }
}

extension OrderDetailViewController: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    /// - Tag: edit_phrase
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            os_log("Error adding voice shortcut: %@", log: OSLog.default, type: .error, error)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            os_log("Error adding voice shortcut: %@", log: OSLog.default, type: .error, error)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

class QuantityTableViewCell: UITableViewCell {
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
}
