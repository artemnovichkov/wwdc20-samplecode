/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a facade to interact with the PoseNet model, includes input
 preprocessing and calling the model's prediction function.
*/

import CoreML
import Vision

protocol PoseNetDelegate: AnyObject {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput)
}

class PoseNet {
    /// The delegate to receive the PoseNet model's outputs.
    weak var delegate: PoseNetDelegate?

    /// The PoseNet model's input size.
    ///
    /// All PoseNet models available from the Model Gallery support the input sizes 257x257, 353x353, and 513x513.
    /// Larger images typically offer higher accuracy but are more computationally expensive. The ideal size depends
    /// on the context of use and target devices, typically discovered through trial and error.
    let modelInputSize = CGSize(width: 513, height: 513)

    /// The PoseNet model's output stride.
    ///
    /// Valid strides are 16 and 8 and define the resolution of the grid output by the model. Smaller strides
    /// result in higher-resolution grids with an expected increase in accuracy but require more computation. Larger
    /// strides provide a more coarse grid and typically less accurate but are computationally cheaper in comparison.
    ///
    /// - Note: The output stride is dependent on the chosen model and specified in the metadata. Other variants of the
    /// PoseNet models are available from the Model Gallery.
    let outputStride = 16

    /// The Core ML model that the PoseNet model uses to generate estimates for the poses.
    ///
    /// - Note: Other variants of the PoseNet model are available from the Model Gallery.
    private let poseNetMLModel: MLModel

    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }

    /// Calls the `prediction` method of the PoseNet model and returns the outputs to the assigned
    /// `delegate`.
    ///
    /// - parameters:
    ///     - image: Image passed by the PoseNet model.
    func predict(_ image: CGImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Wrap the image in an instance of PoseNetInput to have it resized
            // before being passed to the PoseNet model.
            let input = PoseNetInput(image: image, size: self.modelInputSize)

            guard let prediction = try? self.poseNetMLModel.prediction(from: input) else {
                return
            }

            let poseNetOutput = PoseNetOutput(prediction: prediction,
                                              modelInputSize: self.modelInputSize,
                                              modelOutputStride: self.outputStride)

            DispatchQueue.main.async {
                self.delegate?.poseNet(self, didPredict: poseNetOutput)
            }
        }
    }
}
