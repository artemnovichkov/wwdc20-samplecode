/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The implementation of a single-person pose estimation algorithm, based on the TensorFlow
 project "Pose Detection in the Browser."
*/

import CoreGraphics

extension PoseBuilder {
    /// Returns a pose constructed using the outputs from the PoseNet model.
    var pose: Pose {
        var pose = Pose()

        // For each joint, find its most likely position and associated confidence
        // by querying the heatmap array for the cell with the greatest
        // confidence and using this to compute its position.
        pose.joints.values.forEach { joint in
            configure(joint: joint)
        }

        // Compute and assign the confidence for the pose.
        pose.confidence = pose.joints.values
            .map { $0.confidence }.reduce(0, +) / Double(Joint.numberOfJoints)

        // Map the pose joints positions back onto the original image.
        pose.joints.values.forEach { joint in
            joint.position = joint.position.applying(modelToInputTransformation)
        }

        return pose
    }

    /// Sets the joint's properties using the associated cell with the greatest confidence.
    ///
    /// The confidence is obtained from the `heatmap` array output by the PoseNet model.
    /// - parameters:
    ///     - joint: The joint to update.
    private func configure(joint: Joint) {
        // Iterate over the heatmap's associated joint channel to locate the
        // cell with the greatest confidence.
        var bestCell = PoseNetOutput.Cell(0, 0)
        var bestConfidence = 0.0
        for yIndex in 0..<output.height {
            for xIndex in 0..<output.width {
                let currentCell = PoseNetOutput.Cell(yIndex, xIndex)
                let currentConfidence = output.confidence(for: joint.name, at: currentCell)

                // Keep track of the cell with the greatest confidence.
                if currentConfidence > bestConfidence {
                    bestConfidence = currentConfidence
                    bestCell = currentCell
                }
            }
        }

        // Update joint.
        joint.cell = bestCell
        joint.position = output.position(for: joint.name, at: joint.cell)
        joint.confidence = bestConfidence
        joint.isValid = joint.confidence >= configuration.jointConfidenceThreshold
    }
}
