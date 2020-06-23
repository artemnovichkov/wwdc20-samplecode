/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements custom geometry for the Photos project slideshow extension.
*/

import CoreGraphics

extension CGSize {

    var aspectRatio: CGFloat {
        return self.width / self.height
    }

    init(aspectRatio: CGFloat, fitting size: CGSize) {
        let sizeAspectRatio = size.aspectRatio
        var result = size
        if aspectRatio < sizeAspectRatio {
            result.width = size.height * aspectRatio
        } else {
            result.height = size.width / aspectRatio
        }
        self.init(width: result.width, height: result.height)
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }

    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - 0.5 * size.width, y: center.y - 0.5 * size.height, width: size.width, height: size.height)
    }

    init(aspectRatio: CGFloat, fitting rect: CGRect) {
        self.init(center: rect.center, size: CGSize(aspectRatio: aspectRatio, fitting: rect.size))
    }

    mutating func denormalize(in basis: CGRect) {
        origin.x = origin.x * basis.size.width + basis.origin.x
        origin.y = origin.y * basis.size.height + basis.origin.y
        size.width *= basis.size.width
        size.height *= basis.size.height
    }

    func denormalized(in basis: CGRect) -> CGRect {
        var rect = self
        rect.denormalize(in: basis)
        return rect
    }
 
    func zoomRect(in containerSize: CGSize) -> CGRect {
        var zoomRect = CGRect.zero

        let xScale = containerSize.width / self.size.width
        let yScale = containerSize.height / self.size.height
        zoomRect.size.width = containerSize.width * xScale
        zoomRect.size.height = containerSize.height * yScale
        zoomRect.origin.x = -self.origin.x * xScale
        zoomRect.origin.y = -self.origin.y * yScale
        return zoomRect
    }

    mutating func constrainToNormRect() {
        origin.x = max(origin.x, 0)
        origin.y = max(origin.y, 0)
        size.width = min(size.width, 1 - origin.x)
        size.height = min(size.height, 1 - origin.y)
    }

    func distance(to rect: CGRect, in scalingSize: CGSize) -> CGFloat {

        let distance = (pow(minX - rect.minX, 2) + pow(maxX - rect.maxX, 2)) / pow(scalingSize.width, 2)
            + (pow(minY - rect.minY, 2) + pow(maxY - rect.maxY, 2)) / pow(scalingSize.height, 2)
        return distance
    }
}
