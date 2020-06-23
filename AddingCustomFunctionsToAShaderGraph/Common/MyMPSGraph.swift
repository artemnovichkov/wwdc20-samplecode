/*
See LICENSE folder for this sample’s licensing information.

Abstract:
MyMPSGraph file inherits from MPSGraph and adds a custom GeLU method.
*/

import Foundation
import MetalPerformanceShadersGraph

/// Creating the Graph with GeLU method.
class MyMPSGraph: MPSGraph {

    // Creating a GeLU op
    func geLU(tensor: MPSGraphTensor) -> MPSGraphTensor {

        // Create constants needed.
        let ones = constant(withScalar: 1.0, shape: [1], dataType: .float32)
        let half = constant(withScalar: 0.5, shape: [1], dataType: .float32)

        // Create unary math ops.
        let sqrt = squareRoot(with: half, name: nil)

        // Create binary math ops.
        let multiply = multiplication(withPrimaryTensor: sqrt,
                                      secondaryTensor: tensor, name: nil)

        let multiply2 = multiplication(withPrimaryTensor: half,
                                       secondaryTensor: tensor, name: nil)

        let erfValue = erf(with: multiply, name: nil)

        let add = addition(withPrimaryTensor: erfValue,
                           secondaryTensor: ones, name: nil)

        // Return final tensor.
        return multiplication(withPrimaryTensor: multiply2,
                              secondaryTensor: add, name: nil)

    }
}
