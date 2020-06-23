/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main split view controller that is the parent responder implementing all global keyboard shortcuts.
*/

import UIKit

/// - Tag: MainViewController
class MainViewController: UISplitViewController, FileListViewControllerDelegate {
    let fileListViewController = FileListViewController(style: .plain)
    let canvasViewController = CanvasViewController(nibName: nil, bundle: nil)
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        
        fileListViewController.delegate = self
        
        let fileListNavController = UINavigationController(rootViewController: fileListViewController)
        let canvasNavController = UINavigationController(rootViewController: canvasViewController)
        
        viewControllers = [ fileListNavController, canvasNavController ]
        preferredDisplayMode = .oneBesideSecondary
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FileListViewControllerDelegate
    
    func fileListViewController(_: FileListViewController, didSelectFile file: IllustrationFile) {
        canvasViewController.selectedFile = file
    }
}
