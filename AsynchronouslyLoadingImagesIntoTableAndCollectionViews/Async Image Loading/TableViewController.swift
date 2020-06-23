/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UITableViewController of the sample.
*/
import UIKit

class TableViewController: UITableViewController {
    
    var dataSource: UITableViewDiffableDataSource<Section, Item>! = nil

    private var imageObjects = [Item]()
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, item: Item) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            /// - Tag: update
            var content = cell.defaultContentConfiguration()
            content.image = item.image
            ImageCache.publicCache.load(url: item.url as NSURL, item: item) { (fetchedItem, image) in
                if let img = image, img != fetchedItem.image {
                    var updatedSnapshot = self.dataSource.snapshot()
                    if let datasourceIndex = updatedSnapshot.indexOfItem(fetchedItem) {
                        let item = self.imageObjects[datasourceIndex]
                        item.image = img
                        updatedSnapshot.reloadItems([item])
                        self.dataSource.apply(updatedSnapshot, animatingDifferences: true)
                    }
                }
            }
            cell.contentConfiguration = content
            return cell
        }
        
        self.dataSource.defaultRowAnimation = .fade
        
        // Get our image URLs for processing.
        if imageObjects.isEmpty {
                for index in 1...100 {
                    if let url = Bundle.main.url(forResource: "UIImage_\(index)", withExtension: "png") {
                        self.imageObjects.append(Item(image: ImageCache.publicCache.placeholderImage, url: url))
                    }
                }
                var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                initialSnapshot.appendSections([.main])
                initialSnapshot.appendItems(self.imageObjects)
                self.dataSource.apply(initialSnapshot, animatingDifferences: true)
        }
    }
    
}

