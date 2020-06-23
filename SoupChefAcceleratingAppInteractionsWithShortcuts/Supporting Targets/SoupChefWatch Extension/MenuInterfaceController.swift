/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `WKInterfaceController` that displays a menu.
*/

import WatchKit
import Foundation
import SoupKitWatch
import os.log

/// Displays a table of menu items that can be ordered from the watch.
class MenuInterfaceController: WKInterfaceController {
    
    static let controllerIdentifier = "menu"
    private static let confirmOrderSegue = "confirmOrderSegue"
        
    let tableData = SoupMenuManager().findItems(exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem])
    
    @IBOutlet var interfaceTable: WKInterfaceTable!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let order = context as? Order {
            presentController(withName: OrderConfirmedInterfaceController.controllerIdentifier, context: order)
        }
        
        loadTableRows()
    }
    
    override func didAppear() {
        // Inform the system of this activity, as it is one that a shortcut makes easy to repeat.
        let userActivity = NSUserActivity.viewMenuActivity
        update(userActivity)
    }
    
    private func loadTableRows() {
        guard !tableData.isEmpty else { return }
        
        interfaceTable.setNumberOfRows(self.tableData.count, withRowType: "menu")
        
        // Create rows for all of the items in the menu.
        for rowIndex in 0 ... tableData.count - 1 {
            guard let elementRow = interfaceTable.rowController(at: rowIndex) as? MenuItemRowController else {
                os_log("Unexpected row controller")
                return
            }
            let rowData = tableData[rowIndex]
            elementRow.soupName.setText(rowData.localizedName())
            elementRow.soupImage.setImage(UIImage(named: rowData.iconImageName))
        }
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        guard segueIdentifier == MenuInterfaceController.confirmOrderSegue else { return nil }
        
        let menuItem = tableData[rowIndex]
        let newOrder = Order(quantity: 1, menuItem: menuItem, menuItemToppings: [])
        return newOrder
    }
}

/// Defines the layout of a menu item table cell on the watch.
class MenuItemRowController: NSObject {
    @IBOutlet var soupImage: WKInterfaceImage!
    @IBOutlet var soupName: WKInterfaceLabel!
}
