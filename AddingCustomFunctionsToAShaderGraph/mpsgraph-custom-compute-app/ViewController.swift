/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A minimal view controller to execute the tensor function on launch.
*/

import UIKit
import Foundation
import Metal
import MetalPerformanceShaders
import MetalPerformanceShadersGraph

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Custom neuron graph.
        // Create an MPSGraph object.
        let graph = MyMPSGraph()

        // Create placeholder showcasing input to the graph.
        let inputTensor = graph.placeholder(withShape: nil,
                                            dataType: .float32,
                                            name: nil)

        // Call the function to write out a custom neuron graph.
        let geLU = graph.geLU(tensor: inputTensor)

        let device = MTLCreateSystemDefaultDevice()!
        let inputData = MPSNDArray(device: device, scalar: 2.0)

        // Provide input data.
        let inputs = MPSGraphTensorData(mpsndArray: inputData)

        // Execute the graph.
        let results = graph.run(withFeeds: [inputTensor: inputs],
                                targetTensors: [geLU],
                                targetOperations: nil)

        let result = results[geLU]

        let outputNDArray = result?.mpsndarray()

        var outputValues: [Float32] = [-22.0]

        print(outputValues)
        outputNDArray?.readBytes(&outputValues, strideBytes: nil)
        print(outputValues)
    }

}

