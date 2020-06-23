/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The List View Controller.
*/
import UIKit

final class RBListViewController: UITableViewController {

    private var tableData: [RBViewModel]
    
    private var datasource: UITableViewDiffableDataSource<Int, RBViewModel>!
    
    init(viewModels: [RBViewModel]) {
        self.tableData = viewModels
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("RoastedBeans", comment: "")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPressAdd))

        tableView.register(
            UINib(nibName: "RBCell", bundle: nil),
            forCellReuseIdentifier: RBCell.reusedIdentifier)
        tableView.accessibilityLabel = NSLocalizedString("Coffee list", comment: "")

        /*
         This allows for selection of the cell to automatically be trigged when keyboard
         focus moves to a new cell. This can be done by pressing the TAB key to move focus
         to the UITableView and then use the arrow keys to navigate up and down.

         Note that this is set to true automatically when inside a UISplitViewController,
         but if you have your own custom container controllers you will need to do assign
         this yourself. Your UIViewController will also need to be able to become the first
         responder to allow it to take keyboard focus, do so by overriding `canBecomeFirstResponder`.
        */
        tableView.selectionFollowsFocus = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didPressShare),
            name: .shareMenuActivated, object: nil)
        
        datasource = UITableViewDiffableDataSource(
            tableView: tableView, cellProvider: { [self] (table, index, viewModel) -> UITableViewCell? in
                guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: RBCell.reusedIdentifier,
                        for: index) as? RBCell
                else {
                    fatalError("Failed to dequeue cell, was it registered?")
                }
                let data = self.tableData[index.row]
                cell.configure(for: data)
                cell.delegate = self
                return cell
            }
        )
        
        var snapshot = datasource.snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(tableData)
        datasource.apply(snapshot)
    }
    
    @objc
    private func addPressAdd() {
        
    }

    @objc
    private func didPressShare() {
        guard
            let indexPath = tableView.indexPathForSelectedRow,
            let cell = tableView.cellForRow(at: indexPath) as? RBCell
        else {
            return
        }
        didToggleFavorite(cell: cell)
    }
}

// MARK: - RBCellActionProtocol

extension RBListViewController: RBCellActionProtocol {

    func didIncreaseRating(cell: RBCell) {
        guard let path = tableView.indexPath(for: cell) else {
            return
        }
        var data = tableData[path.row]
        if let rating = data.status.rating {
            data.status = .purchased(rating: Status.Rating(rawValue: min(rating.rawValue + 1, 5)))
        } else {
            data.status = .purchased(rating: Status.Rating(rawValue: 1))
        }
        tableData[path.row] = data
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, RBViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(tableData)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    func didDecreaseRating(cell: RBCell) {
        guard let path = tableView.indexPath(for: cell) else {
            return
        }
        var data = tableData[path.row]
        if let rating = data.status.rating {
            if rating.rawValue == 1 {
                data.status = .unpurchased
            } else {
                data.status = .purchased(rating: Status.Rating(rawValue: max(rating.rawValue - 1, 1)))
            }
        }
        tableData[path.row] = data
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, RBViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(tableData)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    func didToggleFavorite(cell: RBCell) {
        guard let path = tableView.indexPath(for: cell) else {
            return
        }
        var data = tableData[path.row]
        data.isFavorite.toggle()
        tableData[path.row] = data
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, RBViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(tableData)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    func didLongPressCell(cell: RBCell) {
        let controller = UIAlertController(
                title: NSLocalizedString("More Options", comment: ""),
                message: "",
                preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(
                title: NSLocalizedString("Copy", comment: ""),
                style: .default,
                handler: nil)
        let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: ""),
                style: .cancel,
                handler: nil)
        controller.addAction(copyAction)
        controller.addAction(cancelAction)
        present(controller, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension RBListViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = tableData[indexPath.row]

        /*
         The UITableView maintain some state regarding which coffee is selected. To
         improve the accessibilityLabel provided to VoiceOver we can better describe the
         view by including which coffee is selected.
        */
        let label = NSLocalizedString("Coffee list", comment: "")
        let selectedLabel = NSLocalizedString("%@ selected", comment: "")
        tableView.accessibilityLabel = label + ", " + String(format: selectedLabel, data.coffee.brand)

        let detailVC = RBDetailViewController(viewModel: data)
        splitViewController?.showDetailViewController(detailVC, sender: nil)
    }

}
