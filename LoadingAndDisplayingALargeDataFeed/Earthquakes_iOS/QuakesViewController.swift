/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UIViewController subclass to manage a table view that displays a collection of quakes.
*/

import UIKit
import CoreData

class QuakesViewController: UITableViewController {
    /**
     The QuakesProvider that fetches quake data, saves it to Core Data,
     and serves it to this table view.
     */
    private lazy var dataProvider: QuakesProvider = {
        
        let provider = QuakesProvider()
        provider.fetchedResultsControllerDelegate = self
        return provider
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if spinner.superview == nil, let superView = tableView.superview {
            superView.addSubview(spinner)
            superView.bringSubviewToFront(spinner)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: superView.centerYAnchor).isActive = true
        }
    }
    
    /**
     Enters  busy UI.
     Ensures the buttons can't be pressed again when the app is busy.
     */
    private func enterBusyUI() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        spinner.startAnimating()
    }

    /**
     Exits busy UI.
     */
    private func exitBusyUI() {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.spinner.stopAnimating()
    }
    
    /**
     Alerts the error or refreshes the table if no error.
     */
    private func handleBatchOperationCompletion(error: Error?) {
        if let error = error {
            let alert = UIAlertController(title: "Executing batch operation error!",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
        } else {
            dataProvider.resetAndRefetch()
            tableView.reloadData()
        }
    }

    /**
     Fetches the remote quake feed when the refresh button is tapped.
     */
    @IBAction func fetchQuakes(_ sender: UIBarButtonItem) {
        enterBusyUI()
        // Use the QuakesProvider to fetch quake data. On completion,
        // handle general UI updates and error alerts on the main queue.
        dataProvider.fetchQuakes { error in
            DispatchQueue.main.async {
                self.exitBusyUI()
                // Alert the error or refresh the table if no error.
                self.handleBatchOperationCompletion(error: error)
            }
        }
    }

    /**
     Deletes all the quake records in the Core Data store when the trash button is tapped.
     */
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
        enterBusyUI()
        dataProvider.deleteAll { error in
            DispatchQueue.main.async {
                self.exitBusyUI()
                self.handleBatchOperationCompletion(error: error)
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension QuakesViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuakeCell", for: indexPath) as? QuakeCell else {
            print("Error: tableView.dequeueReusableCell doesn'return a QuakeCell!")
            return QuakeCell()
        }
        guard let quake = dataProvider.fetchedResultsController.fetchedObjects?[indexPath.row] else { return cell }
        
        cell.configure(with: quake)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
