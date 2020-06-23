/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a structure to hold the PoseNet model's outputs.
*/

import CoreML
import Vision

/// - Tag: PoseNetOutput
struct PoseNetOutput {
    enum Feature: String {
        case heatmap = "heatmap"
        case offsets = "offsets"
        case backwardDisplacementMap = "displacementBwd"
        case forwardDisplacementMap = "displacementFwd"
    }

    /// A structure that defines the coordinates of an index used to query the PoseNet model outputs.
    ///
    /// The PoseNet outputs are arranged in grid. Each cell in the grid corresponds
    /// to a square region of pixels where each side is `outputStride` pixels of the input image.
    struct Cell {
        let yIndex: Int
        let xIndex: Int

        init(_ yIndex: Int, _ xIndex: Int) {
            self.yIndex = yIndex
            self.xIndex = xIndex
        }

        static var zero: Cell {
            return Cell(0, 0)
        }
    }

    /// A multidimensional array that stores the confidence for each joint.
    ///
    /// The layout of the array is `[joint][y][x]`, where `joint` is the index of the associated
    /// joint and, `y` and `x` is the vertical and horizontal grid cell indices respectively.
    let heatmap: MLMultiArray

    /// A multidimensional array that stores an offset for each joint.
    ///
    /// The layout of the array is `[joint][y][x]` where `joint` is the index of the associated joint
    /// and, `y` and `x` is the vertical and horizontal grid cell indices respectively.
    let offsets: MLMultiArray

    /// A multidimensional array that stores the displacement vector from each joint to its parent.
    ///
    /// The layout of the array is `[edge][y][x]` where `edge` is the index of the associated joint pair
    /// and, `y` and `x` is the vertical and horizontal grid cell indices respectively.
    ///
    /// - Note: This is only used when detecting multiple poses.
    let backwardDisplacementMap: MLMultiArray

    /// A multidimensional array that stores the displacement vector from each parent joint to one of its children.
    ///
    /// The layout of the array is `[edge][y][x]` where `edge` is the index of the associated joint pair
    /// and, `y` and `x` is the vertical and horizontal grid cell indices respectively.
    ///
    /// - Note: This is only used when detecting multiple poses.
    let forwardDisplacementMap: MLMultiArray

    /// The PoseNet model's input size.
    ///
    /// All PoseNet models available from the Model Gallery support the input sizes 257x257, 353x353, and 513x513.
    /// Larger images typically offer higher accuracy but are more computationally expensive. The ideal size depends
    /// on the context of use and target devices, typically discovered through trial and error.
    let modelInputSize: CGSize

    /// The PoseNet model's output stride.
    ///
    /// Valid strides are 16 and 8 and define the resolution of the grid output by the model. Smaller strides
    /// result in higher resolution grids with an expected increase in accuracy but require more computation. Larger
    /// strides provide a more coarse grid and typically less accurate but are computationally cheaper in comparison.
    ///
    /// - Note: The output stride is dependent on the chosen model and specified in the metadata. Other variants of the
    /// PoseNet model are available from the Model Gallery.
    let modelOutputStride: Int

    /// Returns the **height** of the output array (`heatmap.shape[1]`).
    var height: Int {
        return heatmap.shape[1].intValue
    }

    /// Returns the **width** of the output array (`heatmap.shape[2]`).
    var width: Int {
        return heatmap.shape[2].intValue
    }

    init(prediction: MLFeatureProvider, modelInputSize: CGSize, modelOutputStride: Int) {
        guard let heatmap = prediction.multiArrayValue(for: .heatmap) else {
            fatalError("Failed to get the heatmap MLMultiArray")
        }
        guard let offsets = prediction.multiArrayValue(for: .offsets) else {
            fatalError("Failed to get the offsets MLMultiArray")
        }
        guard let backwardDisplacementMap = prediction.multiArrayValue(for: .backwardDisplacementMap) else {
            fatalError("Failed to get the backwardDisplacementMap MLMultiArray")
        }
        guard let forwardDisplacementMap = prediction.multiArrayValue(for: .forwardDisplacementMap) else {
            fatalError("Failed to get the forwardDisplacementMap MLMultiArray")
        }

        self.heatmap = heatmap
        self.offsets = offsets
        self.backwardDisplacementMap = backwardDisplacementMap
        self.forwardDisplacementMap = forwardDisplacementMap

        self.modelInputSize = modelInputSize
        self.modelOutputStride = modelOutputStride
    }
}

// MARK: - Utility and accessor methods

extension PoseNetOutput {
    /// Calculates and returns the position for a given joint type at the specified grid cell.
    ///
    /// The joint's position is calculated by multiplying the y and x indices by the model's output stride
    /// plus the associated offset encoded in the PoseNet model's `offsets` array.
    ///
    /// - parameters:
    ///     - jointName: Query joint used to index the `offsets` array.
    ///     - cell: The coordinates in `offsets` output for the given joint name.
    /// - returns: Calculated position for the specified joint and grid cell.
    func position(for jointName: Joint.Name, at cell: Cell) -> CGPoint {
        let jointOffset = offset(for: jointName, at: cell)

        // First, calculate the joint’s coarse position.
        var jointPosition = CGPoint(x: cell.xIndex * modelOutputStride,
                                    y: cell.yIndex * modelOutputStride)

        // Then, add the offset to get a precise position.
        jointPosition += jointOffset

        return jointPosition
    }

    /// Returns the cell for a given position.
    ///
    /// - parameters:
    ///     - position: Position to map to an index.
    /// - returns: Mapped cell index.
    func cell(for position: CGPoint) -> Cell? {
        let yIndex = Int((position.y / CGFloat(modelOutputStride))
            .rounded())
        let xIndex = Int((position.x / CGFloat(modelOutputStride))
            .rounded())

        guard yIndex >= 0 && yIndex < height
            && xIndex >= 0 && xIndex < width else {
                return nil
        }

        return Cell(yIndex, xIndex)
    }

    /// Returns the associated offset for a joint at the specified cell index.
    ///
    /// Queries the `offsets` array at position `[jointName, cell.yIndex, cell.xIndex]` for the vertical
    /// component and `[jointName + <number of joints>, cell.yIndex, cell.xIndex]` for the
    /// horizontal component.
    ///
    /// - parameters:
    ///     - jointName: Joint name whose `rawValue` is used as the index of the first dimension of the `offsets` array.
    ///     - cell: The coordinates in the `offsets` output for the given joint name.
    func offset(for jointName: Joint.Name, at cell: Cell) -> CGVector {
        // Create the index for the y and x component of the offset.
        let yOffsetIndex = [jointName.rawValue, cell.yIndex, cell.xIndex]
        let xOffsetIndex = [jointName.rawValue + Joint.numberOfJoints, cell.yIndex, cell.xIndex]

        // Obtain y and x component of the offset from the offsets array.
        let offsetY: Double = offsets[yOffsetIndex].doubleValue
        let offsetX: Double = offsets[xOffsetIndex].doubleValue

        return CGVector(dx: CGFloat(offsetX), dy: CGFloat(offsetY))
    }

    /// Returns the associated confidence for a joint at the specified index.
    ///
    /// Queries the `heatmap` array at position `[jointName, index.y, index.x]` for the joint's
    /// associated confidence value.
    ///
    /// - parameters:
    ///     - jointName: Joint name whose `rawValue` is used as the index of the first dimension of the `heatmap` array.
    ///     - cell: The coordinates in `heatmap` output for the given joint name.
    func confidence(for jointName: Joint.Name, at cell: Cell) -> Double {
        let multiArrayIndex = [jointName.rawValue, cell.yIndex, cell.xIndex]
        return heatmap[multiArrayIndex].doubleValue
    }

    /// Returns the forward displacement vector for the specified edge and index.
    ///
    /// - parameters:
    ///     - edgeIndex: Index of the first dimension of the `forwardDisplacementMap` array.
    ///     - cell: The coordinates in `forwardDisplacementMap` output for the given edge.
    /// - returns: Displacement vector for `edge` at index `yIndex` and `xIndex`.
    func forwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        // Create the MLMultiArray index
        let yEdgeIndex = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]

        // Extract the displacements from MultiArray
        let displacementY = forwardDisplacementMap[yEdgeIndex].doubleValue
        let displacementX = forwardDisplacementMap[xEdgeIndex].doubleValue

        return CGVector(dx: displacementX, dy: displacementY)
    }

    /// Returns the backwards displacement vector for the specified edge and cell.
    ///
    /// - parameters:
    ///     - edgeIndex: Index of the first dimension of the `backwardDisplacementMap` array.
    ///     - cell: The coordinates in `backwardDisplacementMap` output for the given edge.
    /// - returns: Displacement vector for `edge` at index `yIndex` and `xIndex`.
    func backwardDisplacement(for edgeIndex: Int, at cell: Cell) -> CGVector {
        // Create the MLMultiArray index
        let yEdgeIndex = [edgeIndex, cell.yIndex, cell.xIndex]
        let xEdgeIndex = [edgeIndex + Pose.edges.count, cell.yIndex, cell.xIndex]

        // Extract the displacements from MultiArray
        let displacementY = backwardDisplacementMap[yEdgeIndex].doubleValue
        let displacementX = backwardDisplacementMap[xEdgeIndex].doubleValue

        return CGVector(dx: displacementX, dy: displacementY)
    }
}

// MARK: - MLFeatureProvider extension

extension MLFeatureProvider {
    func multiArrayValue(for feature: PoseNetOutput.Feature) -> MLMultiArray? {
        return featureValue(for: feature.rawValue)?.multiArrayValue
    }
}

// MARK: - MLMultiArray extension

extension MLMultiArray {
    subscript(index: [Int]) -> NSNumber {
        return self[index.map { NSNumber(value: $0) } ]
    }
}
