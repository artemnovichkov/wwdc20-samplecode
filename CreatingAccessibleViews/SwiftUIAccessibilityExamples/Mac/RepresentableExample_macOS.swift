/*
See LICENSE folder for this sample’s licensing information.

Abstract:
macOS NSViewRepresentable implementations
*/

import Foundation
import SwiftUI
import AppKit

final class RepresentableNSView: NSView {
    var color: NSColor

    init(_ color: NSColor) {
        self.color = color
        super.init(frame: .zero)
        self.wantsLayer = true
        self.setAccessibilityElement(true)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    override func updateLayer() {
        guard let layer = self.layer else {
            return
        }
        layer.backgroundColor = color.cgColor
        layer.cornerRadius = defaultCornerRadius
        layer.borderColor = NSColor.black.cgColor
        layer.borderWidth = 2
    }
}

struct RepresentableView: NSViewRepresentable {
    func makeNSView(context: NSViewRepresentableContext<RepresentableView>) -> RepresentableNSView {
        return RepresentableNSView(.red)
    }

    func updateNSView(_ nsView: RepresentableNSView, context: NSViewRepresentableContext<RepresentableView>) {
    }
}

final class RepresentableNSViewController: NSViewController {
    override func loadView() {
        self.view = RepresentableNSView(.blue)
    }
}

struct RepresentableViewController: NSViewControllerRepresentable {
    func makeNSViewController(context: NSViewControllerRepresentableContext<RepresentableViewController>) -> RepresentableNSViewController {
        return RepresentableNSViewController()
    }

    func updateNSViewController(_ nsViewController: RepresentableNSViewController,
                                context: NSViewControllerRepresentableContext<RepresentableViewController>) {
    }
}
