/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the slide view controller for the Photos project slideshow extension.
*/

import Cocoa
import PhotosUI

class SlideViewController: NSViewController {

    @IBOutlet var imageView: SimpleImageView!

    private var contentMode: PHImageContentMode = .aspectFit
    private let imageManager = PHImageManager.default()
    private var requestID = PHInvalidImageRequestID

    var assetModel: AssetModel?

    deinit {
        imageManager.cancelImageRequest(requestID)
    }

    func preload(assetModel: AssetModel, targetSize: CGSize) {
        self.assetModel = assetModel
        if requestID != PHInvalidImageRequestID {
            imageManager.cancelImageRequest(requestID)
        }
        guard let asset = assetModel.asset else { return }

        // force load view
        _ = view

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        requestID = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { (image, _) in
            self.imageView.image = image
        }
    }

}
