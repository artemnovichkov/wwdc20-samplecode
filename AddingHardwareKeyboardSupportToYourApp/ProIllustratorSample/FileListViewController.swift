/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that shows a list of files.
*/

import UIKit

protocol FileListViewControllerDelegate: class {
    func fileListViewController(_: FileListViewController, didSelectFile file: IllustrationFile)
}

/// - Tag: FileListViewController
class FileListViewController: UITableViewController {
    static let reuseIdentifier = "file.item"
    
    var store = FileStore()
    weak var delegate: FileListViewControllerDelegate?
    var tableViewDataSource: UITableViewDiffableDataSource<Int, Int>?
    
    override var canBecomeFirstResponder: Bool {
        // When implementing keyboard shortcuts for a view controller, make
        // sure to override and return true.
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("FILES", comment: "Title for file list")
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewItem))
        
        tableViewDataSource = UITableViewDiffableDataSource<Int, Int>(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
                let cell = tableView.dequeueReusableCell(withIdentifier: FileListViewController.reuseIdentifier, for: indexPath)
                cell.textLabel?.text = self.store.itemForIdentifier(item)?.name

                return cell
            }
        )

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: FileListViewController.reuseIdentifier)
        tableView.dataSource = tableViewDataSource
        
        if var snapshot = tableViewDataSource?.snapshot() {
            snapshot.appendSections([ 0 ])
            snapshot.appendItems(store.allIdentifiers())
            
            tableViewDataSource?.apply(snapshot)
        }
    }
    
    // MARK: UITableViewDelegate methods
    /// - Tag: MultipleSelectionInteraction
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When selection changes, become first responder. This happens
        // automatically in Mac Catalyst.
        becomeFirstResponder()
        
        guard let dataSource = tableViewDataSource else { return }
        if let identifier = dataSource.itemIdentifier(for: indexPath), let delegate = delegate {
            if let selectedFile = store.itemForIdentifier(identifier) {
                delegate.fileListViewController(self, didSelectFile: selectedFile)
            }
        }
    }
    
    // MARK: Multiple Selection API
    
    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        // Return true to allow Shift-click to select multiple rows in the
        // table view, and Command-click to append to the current selection.
        return true
    }
    
    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // Important: In this method, update the surrounding UI to reflect the
        // fact that the system automatically places the table view into edit
        // mode. Since this code uses a standard UITableViewController, setting
        // isEditing to true automatically updates the editButtonItem to show
        // "Done" instead of "Edit", and configures its action to toggle back
        // to normal selection mode.
        self.isEditing = true
    }
    
    override func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        // You may optionally do something here when multiple selection ends.
        // The table view calls this method after the user selects a new set of
        // rows using Shift-click, or when a two-finger gesture ends.
    }
    
    // MARK: UIResponderStandardEditActions
    
    override func selectAll(_ sender: Any?) {
        // Select all rows in the table.
        isEditing = true
        for row in 0...tableViewDataSource!.tableView(tableView, numberOfRowsInSection: 0) {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
    }
}

extension FileListViewController: GlobalKeyboardShortcutRespondable {
    func createNewItem(_: Any?) {
        let newFile = store.createNewFile()
        
        if let dataSource = tableViewDataSource {
            var snapshot = dataSource.snapshot()
            snapshot.appendItems([ newFile.identifier ])
            dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        }
    }
    
    func deleteSelectedItem(_: Any?) {
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows, let dataSource = tableViewDataSource {
            var snapshot = dataSource.snapshot()
            
            for selectedIndex in selectedIndexPaths {
                if let identifier = dataSource.itemIdentifier(for: selectedIndex) {
                    store.deleteItemWithIdentifier(identifier)
                    snapshot.deleteItems([ identifier ])
                }
            }
            
            dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
        }
    }
}
