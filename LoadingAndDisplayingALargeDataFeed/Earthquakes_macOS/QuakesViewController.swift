/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An NSViewController subclass to manage a table view that displays a collection of quakes.
*/

import Cocoa
import CoreData

class QuakesViewController: NSViewController {
    
    @IBOutlet weak private var tableView: NSTableView!
    @IBOutlet weak private var fetchQuakesButton: NSButton!
    @IBOutlet weak private var deleteAllButton: NSButton!
    @IBOutlet weak private var progressIndicator: NSProgressIndicator!

    // MARK: Core Data
    
    /**
     The QuakesProvider that fetches quake data, saves it to Core Data,
     and serves it to the table view.
     */
    private lazy var dataProvider: QuakesProvider = {
        let provider = QuakesProvider()
        provider.fetchedResultsControllerDelegate = self
        return provider
    }()
    
    /**
     Enters busy UI.
     Ensures the buttons can't be pressed again when the app is busy.
     */
    private func enterBusyUI() {
        fetchQuakesButton.isEnabled = false
        deleteAllButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
    }

    /**
     Exits busy UI.
     */
    private func exitBusyUI() {
        fetchQuakesButton.isEnabled = true
        deleteAllButton.isEnabled = true
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)
    }
    
    /**
     Alerts the error or refreshes the table if no error.
     */
    private func handleBatchOperationCompletion(error: Error?) {
        if let error = error {
            NSApp.presentError(error)
        } else {
            dataProvider.resetAndRefetch()
            tableView.reloadData()
        }
    }
    
    /**
     Fetches the remote quake feed when the refresh button is pressed.
     */
    @IBAction private func fetchQuakes(_ sender: AnyObject) {
        enterBusyUI()
        dataProvider.fetchQuakes { error in
            DispatchQueue.main.async {
                self.exitBusyUI()
                self.handleBatchOperationCompletion(error: error)
            }
        }
    }
    
    /**
     Deletes all the quake records in the Core Data store when the trash button is tapped.
     */
    @IBAction func deleteAll(_ sender: AnyObject) {
        enterBusyUI()
        dataProvider.deleteAll { error in
            DispatchQueue.main.async {
                self.exitBusyUI()
                self.handleBatchOperationCompletion(error: error)
            }
        }
    }
}

// MARK: - NSTableViewDelegate

extension QuakesViewController: NSTableViewDelegate {}

// MARK: - NSTableViewDataSource

extension QuakesViewController: NSTableViewDataSource {
    /**
     The names of earthquake properties to be displayed in the table view.
     */
    private enum QuakeDisplayProperty: String {
        case place
        case time
        case magnitude
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            assertionFailure("Table column is nil.")
            return nil
        }
        
        guard let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView,
            let propertyEnum = QuakeDisplayProperty(rawValue: identifier.rawValue) else { return nil }
        
        if let quake = dataProvider.fetchedResultsController.fetchedObjects?[row],
            let textField = cellView.textField {
            
            switch propertyEnum {
            case .place:
                textField.stringValue = quake.place ?? ""
                
            case .time:
                textField.objectValue = quake.time
                
            case .magnitude:
                textField.objectValue = quake.magnitude
            }
        }
        return cellView
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension QuakesViewController: NSFetchedResultsControllerDelegate {
    /**
     Reloads the table view when the fetched result controller's content changes.
     */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}
