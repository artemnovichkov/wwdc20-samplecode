/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SwiftUI Wrapper on `AVCaptureVideoPreviewLayer`.
*/

import SwiftUI
import UIKit
import AVFoundation

struct PreviewView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIPreviewView {
        let previewView = UIPreviewView(frame: .zero)
        
        context.environment.blurDetector.configure()
        
        previewView.session = context.environment.blurDetector.captureSession

        return previewView
    }

    func updateUIView(_ uiView: UIPreviewView, context: UIViewRepresentableContext<PreviewView>) {
        uiView.videoPreviewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        uiView.videoPreviewLayer.connection?.isVideoMirrored = false
    }
}

class UIPreviewView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check UIPreviewView.layerClass implementation.")
        }

        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if
            let interfaceOrientation = window?.windowScene?.interfaceOrientation,
            let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation) {
            
            session?.connections.forEach {
                $0.videoOrientation = videoOrientation
            }
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
