/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `WKInterfaceController` that displays a list of previously placed orders.
*/

import WatchKit
import Foundation
import SoupKitWatch
import os.log

class HistoryInterfaceController: WKInterfaceController {

    static let controllerIdentifier = "history"
    
    let tableData = SoupOrderDataManager().orderHistory
    
    @IBOutlet var interfaceTable: WKInterfaceTable!
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        loadTableRows()
    }
    
    func loadTableRows() {
        guard !tableData.isEmpty else { return }
        
        interfaceTable.setNumberOfRows(self.tableData.count, withRowType: "history")
        
        // Create rows for all of the items in the menu.
        for rowIndex in 0 ... tableData.count - 1 {
            guard let elementRow = interfaceTable.rowController(at: rowIndex) as? HistoryItemRowController else {
                os_log("Unexpected row controller")
                return
            }
            
            let rowData = tableData[rowIndex]
            let dateString = dateFormatter.string(from: rowData.date)
            elementRow.itemOrdered.setText(rowData.menuItem.localizedName())
            elementRow.orderTime.setText(dateString)
        }
    }
}

class HistoryItemRowController: NSObject {
    @IBOutlet var itemOrdered: WKInterfaceLabel!
    @IBOutlet var orderTime: WKInterfaceLabel!
}
