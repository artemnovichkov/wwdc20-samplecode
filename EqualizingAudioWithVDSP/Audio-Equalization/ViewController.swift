/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of iOS view controller that demonstrates audio equalization.
*/

import UIKit
import Accelerate

let sampleCount = 1024

class ViewController: UIViewController {
    
    var equalizationMode: EqualizationMode = .flat {
        didSet {
            if let multiplier = equalizationMode.dctMultiplier() {
                GraphUtility.drawGraphInLayer(envelopeLayer,
                                              strokeColor: UIColor.red.withAlphaComponent(0.25).cgColor,
                                              lineWidth: 1,
                                              values: multiplier,
                                              minimum: -1,
                                              maximum: 2)
            } else {
                envelopeLayer.path = nil
            }
        }
    }
    
    @IBOutlet var segmentedControl: UISegmentedControl!

    @IBAction func segmentedControlHandler(_ sender: Any) {
        guard
            let segmentedControl = sender as? UISegmentedControl,
            let modeName = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex),
            let mode = EqualizationMode(rawValue: modeName) else {
                return
        }
        
        switch mode {
        case .biquadLowPass:
            biquadFilter = vDSP.Biquad(coefficients: EqualizationFilters.biquadLowPass,
                                       channelCount: 1,
                                       sectionCount: 1,
                                       ofType: Float.self)
        case .biquadHighPass:
            biquadFilter = vDSP.Biquad(coefficients: EqualizationFilters.biquadHighPass,
                                       channelCount: 1,
                                       sectionCount: 1,
                                       ofType: Float.self)
        default:
            break
        }
        
        equalizationMode = mode
    }
    
    var biquadFilter: vDSP.Biquad<Float>?
    
    let forwardDCT = vDSP.DCT(count: sampleCount,
                              transformType: .II)
    
    let inverseDCT = vDSP.DCT(count: sampleCount,
                              transformType: .III)
    
    var frequencyDomainGraphLayerIndex = 0
    let frequencyDomainGraphLayers = [CAShapeLayer(), CAShapeLayer(),
                                      CAShapeLayer(), CAShapeLayer()]
    
    let envelopeLayer = CAShapeLayer()
    
    lazy var forwardDCT_PreProcessed = [Float](repeating: 0,
                                               count: sampleCount)
    
    lazy var forwardDCT_PostProcessed = [Float](repeating: 0,
                                                count: sampleCount)
    
    lazy var inverseDCT_Result = [Float](repeating: 0,
                                  count: sampleCount)
    
    let samples: [Float] = {
        guard let samples = AudioUtilities.getAudioSamples(
            forResource: "Rhythm",
            withExtension: "aif") else {
                fatalError("Unable to parse the audio resource.")
        }
        
        return samples
    }()
    
    var pageNumber = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.removeAllSegments()
        EqualizationMode.allCases.forEach {
            segmentedControl.insertSegment(withTitle: $0.rawValue,
                                           at: segmentedControl.numberOfSegments,
                                           animated: false)
        }
        
        if let defaultIndex = EqualizationMode.allCases.firstIndex(of: equalizationMode) {
            segmentedControl.selectedSegmentIndex = defaultIndex
        }
        
        frequencyDomainGraphLayers.forEach {
            view.layer.addSublayer($0)
        }
        
        envelopeLayer.fillColor = nil
        view.layer.addSublayer(envelopeLayer)

        AudioUtilities.configureAudioUnit(signalProvider: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        frequencyDomainGraphLayers.forEach {
            $0.frame = view.frame.insetBy(dx: 0, dy: 50)
        }
        
        envelopeLayer.frame = view.frame.insetBy(dx: 0, dy: 50)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

