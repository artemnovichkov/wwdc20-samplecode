/*
See LICENSE folder for this sample’s licensing information.

Abstract:
iOS NSViewRepresentable implementations
*/

import Foundation
import SwiftUI
import UIKit

final class RepresentableUIView: UIView {
    var color: UIColor

    init(_ color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        self.isAccessibilityElement = true
        layer.backgroundColor = color.cgColor
        layer.cornerRadius = defaultCornerRadius
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

struct RepresentableView: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<RepresentableView>) -> RepresentableUIView {
        return RepresentableUIView(.red)
    }

    func updateUIView(_ nsView: RepresentableUIView, context: UIViewRepresentableContext<RepresentableView>) {
    }
}

final class RepresentableUIViewController: UIViewController {
    override func loadView() {
        self.view = RepresentableUIView(.blue)
    }
}

struct RepresentableViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<RepresentableViewController>) -> RepresentableUIViewController {
        return RepresentableUIViewController()
    }

    func updateUIViewController(_ nsViewController: RepresentableUIViewController,
                                context: UIViewControllerRepresentableContext<RepresentableViewController>) {
    }
}
