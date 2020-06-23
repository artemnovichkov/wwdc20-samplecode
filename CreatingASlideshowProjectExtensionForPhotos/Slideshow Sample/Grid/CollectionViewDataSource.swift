/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the collection view data source for the Photos project slideshow extension.
*/

import Cocoa

class CollectionViewDataSource: NSObject, NSCollectionViewDataSource {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("assetCollectionViewItem")
    var assetModels = [AssetModel]()

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetModels.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: CollectionViewDataSource.reuseIdentifier, for: indexPath)
        item.representedObject = assetModels[indexPath.item]
        return item
    }
}
