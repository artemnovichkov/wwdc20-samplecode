/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UIActivityIndicatorView`.
*/

import UIKit

class ActivityIndicatorViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultSmallActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var defaultLargeActivityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var tintedSmallActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var tintedLargeActivityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDefaultActivityIndicatorView()
        configureTintedActivityIndicatorView()
        
        // When the activity is done, be sure to use UIActivityIndicatorView.stopAnimating().
    }
    
    // MARK: - Configuration

    func configureDefaultActivityIndicatorView() {
        defaultSmallActivityIndicatorView.style = UIActivityIndicatorView.Style.medium
        defaultLargeActivityIndicatorView.style = UIActivityIndicatorView.Style.large
        
        defaultSmallActivityIndicatorView.startAnimating()
        defaultLargeActivityIndicatorView.startAnimating()
        
        defaultSmallActivityIndicatorView.hidesWhenStopped = true
        defaultLargeActivityIndicatorView.hidesWhenStopped = true
    }
    
    func configureTintedActivityIndicatorView() {
    	tintedSmallActivityIndicatorView.style = UIActivityIndicatorView.Style.medium
        tintedLargeActivityIndicatorView.style = UIActivityIndicatorView.Style.large
        
        tintedSmallActivityIndicatorView.color = UIColor.systemPurple
        tintedLargeActivityIndicatorView.color = UIColor.systemPurple
        
        tintedSmallActivityIndicatorView.startAnimating()
        tintedLargeActivityIndicatorView.startAnimating()
    }
}
