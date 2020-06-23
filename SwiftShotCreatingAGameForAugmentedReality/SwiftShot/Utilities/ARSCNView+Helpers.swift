/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for generating screeshots from ARSCNView.
*/

import ARKit
import os.log

extension ARSCNView {
    func createScreenshot(interfaceOrientation: UIDeviceOrientation) -> UIImage? {
        guard let frame = session.currentFrame else {
            os_log(.error, "Error: Failed to create a screenshot - no current ARFrame exists.")
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
        let scaledImage = ciImage.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: 0.5,
            kCIInputAspectRatioKey: 1.0])
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        if let cgimage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            var orientation: UIImage.Orientation = .right
            switch interfaceOrientation {
            case .portrait:
                orientation = .right
            case .portraitUpsideDown:
                orientation = .left
            case .landscapeLeft:
                orientation = .up
            case .landscapeRight:
                orientation = .down
            default:
                break
            }
            return UIImage(cgImage: cgimage, scale: 1.0, orientation: orientation)
        }
        return nil
    }
}
