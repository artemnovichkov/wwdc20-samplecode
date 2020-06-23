/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extends the slide view controller to animate according to zoom.
*/

import CoreGraphics

extension SlideViewController: AnimatableSlide {

    var contentAspectRatio: CGFloat? {
        guard let asset = assetModel?.asset else {
            return nil
        }
        return CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
    }

    var preferredZoomRect: CGRect? {
        return self.assetModel?.preferredZoomRect
    }
}
