/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements an asset collection item for the Photos project slideshow extension.
*/

import Cocoa
import Photos

class AssetCollectionViewItem: NSCollectionViewItem {

    override var representedObject: Any? {
        didSet {
            update()
        }
    }
    var assetModel: AssetModel? {
        return representedObject as? AssetModel
    }
    var requestId = PHInvalidImageRequestID
    let imageManager = PHImageManager.default()

    func update() {
        guard let assetModel = assetModel, let asset = assetModel.asset else {
            return
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        let size = (imageView ?? view).bounds.size
        requestId = imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { [weak self](image, _) in
            self?.update(image: image)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageManager.cancelImageRequest(requestId)
    }

    func update(image: NSImage?) {
        self.imageView?.image = image
    }
 
}
