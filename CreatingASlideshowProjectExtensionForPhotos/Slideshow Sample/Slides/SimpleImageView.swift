/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements a simple image view for the Photos project slideshow extension.
*/

import Cocoa

class SimpleImageView: NSView {

    var image: NSImage? {
        didSet {
            layer?.contents = image
        }
    }

    func commonInit() {
        wantsLayer = true
        layer?.contentsGravity = .resizeAspect
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

}
