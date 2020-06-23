/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension to view controller to implement `SignalProvider` protocol.
*/

import UIKit
import Accelerate

extension ViewController: SignalProvider {
    // Returns a page containing `sampleCount` samples from the
    // `samples` array and increments `pageNumber`.
    func getSignal() -> [Float] {
        let start = pageNumber * sampleCount
        let end = (pageNumber + 1) * sampleCount
        
        let page = Array(samples[start ..< end])
        
        pageNumber += 1
        
        if (pageNumber + 1) * sampleCount >= samples.count {
            pageNumber = 0
        }
        
        let outputSignal: [Float]
        
        switch equalizationMode.category {
            case .biquad:
                outputSignal = apply(toInput: page)
            case let .dct(dctMultiplier):
                outputSignal = apply(dctMultiplier: dctMultiplier, toInput: page)
            case .passThrough:
                outputSignal = page
        }
        
        renderSignalAsFrequencyDomainGraph(signal: outputSignal)
        
        return outputSignal
    }
    
    // Applies `biquadFilter` to the values in `input` and
    // returns the result.
    func apply(toInput input: [Float]) -> [Float] {
        return biquadFilter!.apply(input: input)
    }
    
    // Multiplies the frequency-domain representation of `input` by
    // `dctMultiplier`, and returns the temporal-domain representation
    // of the product.
    func apply(dctMultiplier: [Float], toInput input: [Float]) -> [Float] {
        // Perform forward DCT.
        forwardDCT?.transform(input,
                              result: &forwardDCT_PreProcessed)
        // Multiply frequency-domain data by `dctMultiplier`.
        vDSP.multiply(dctMultiplier,
                      forwardDCT_PreProcessed,
                      result: &forwardDCT_PostProcessed)
        
        // Perform inverse DCT.
        inverseDCT?.transform(forwardDCT_PostProcessed,
                              result: &inverseDCT_Result)
        
        // In-place scale inverse DCT result by n / 2.
        // Output samples are now in range -1...+1
        vDSP.divide(inverseDCT_Result,
                    Float(sampleCount / 2),
                    result: &inverseDCT_Result)
        
        return inverseDCT_Result
    }
    
    func renderSignalAsFrequencyDomainGraph(signal: [Float]) {
        guard let frequencyDomain = forwardDCT?.transform(signal) else {
            return
        }
        
        DispatchQueue.main.async {
            let index = self.frequencyDomainGraphLayerIndex % self.frequencyDomainGraphLayers.count
            
            GraphUtility.drawGraphInLayer(self.frequencyDomainGraphLayers[index],
                                          strokeColor: UIColor.blue.withAlphaComponent(1).cgColor,
                                          lineWidth: 2,
                                          values: frequencyDomain,
                                          minimum: -20,
                                          maximum: 20,
                                          hScale: 1)
            
            self.frequencyDomainGraphLayers.forEach {
                if let alpha = $0.strokeColor?.alpha {
                    $0.strokeColor = UIColor.blue.withAlphaComponent(alpha * 0.75).cgColor
                }
            }
            
            self.frequencyDomainGraphLayerIndex += 1
        }
    }
}
