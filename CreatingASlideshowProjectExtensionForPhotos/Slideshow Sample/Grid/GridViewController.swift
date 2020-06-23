/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the grid collection view controller for the Photos project slideshow extension.
*/

import Cocoa
import PhotosUI

class GridViewController: NSViewController {

    @IBOutlet var collectionView: NSCollectionView!
    let dataSource = CollectionViewDataSource()
    var models = [AssetModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(AssetCollectionViewItem.self, forItemWithIdentifier: CollectionViewDataSource.reuseIdentifier)
        collectionView.dataSource = dataSource
    }

    func loadCollectionView(project: ProjectModel, extensionContext: PHProjectExtensionContext) {
        let projectInfo = project.projectInfo
        let models = AssetModel.models(forProjectInfo: projectInfo, project: extensionContext.project, library: extensionContext.photoLibrary)
        self.models = models
        dataSource.assetModels = models
        collectionView.reloadData()
    }
}
