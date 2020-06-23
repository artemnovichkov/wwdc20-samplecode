/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use a default `UISearchBar`.
*/

import UIKit

class DefaultSearchBarViewController: UIViewController {
    // MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchBar()
    }

    // MARK: - Configuration
    
    func configureSearchBar() {
        searchBar.showsCancelButton = true
		searchBar.showsScopeBar = true
        
        searchBar.scopeButtonTitles = [
            NSLocalizedString("Scope One", comment: ""),
            NSLocalizedString("Scope Two", comment: "")
        ]
    }

}

// MARK: - UISearchBarDelegate

extension DefaultSearchBarViewController: UISearchBarDelegate {
	func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		print("The default search selected scope button index changed to \(selectedScope).")
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		print("The default search bar keyboard search button was tapped: \(String(describing: searchBar.text)).")
		
		searchBar.resignFirstResponder()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		print("The default search bar cancel button was tapped.")
		
		searchBar.resignFirstResponder()
	}
	
}
