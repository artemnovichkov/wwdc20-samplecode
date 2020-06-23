/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Enum containing equalization filters.
*/

import Accelerate

enum EqualizationMode: String, CaseIterable {
    case dctLowPass = "DCT Low-Pass"
    case dctHighPass = "DCT High-Pass"
    case dctBandPass = "DCT Band-Pass"
    case dctBandStop = "DCT Band-Stop"
    case biquadLowPass = "Biquad Low-Pass"
    case biquadHighPass = "Biquad High-Pass"
    case flat = "Flat"

    func dctMultiplier() -> [Float]? {
        let multiplier: [Float]?
        
        switch self {
            case .dctHighPass:
                multiplier = EqualizationFilters.dctHighPass
            case .dctLowPass:
                multiplier = EqualizationFilters.dctLowPass
            case .dctBandPass:
                multiplier = EqualizationFilters.dctBandPass
            case .dctBandStop:
                multiplier = EqualizationFilters.dctBandStop
            default:
                multiplier = nil
        }
        
        return multiplier
    }
    
    func biquadCoefficients() -> [Double]? {
        let coefficients: [Double]?
        
        switch self {
            case .biquadHighPass:
                coefficients = EqualizationFilters.biquadHighPass
            case .biquadLowPass:
                coefficients = EqualizationFilters.biquadLowPass
            default:
                coefficients = nil
        }
        
        return coefficients
    }
    
    var category: Category {
        switch self {
            case .biquadLowPass, .biquadHighPass:
                return .biquad(biquadCoefficients()!)
            case .dctBandStop, .dctBandPass, .dctLowPass, .dctHighPass:
                return .dct(dctMultiplier()!)
            case .flat:
                return .passThrough
        }
    }
    
    enum Category {
        case dct([Float])
        case biquad([Double])
        case passThrough
    }
}

struct EqualizationFilters {
    
    static let biquadLowPass: [Double] = {
        let b0 = 0.0001
        let b1 = 0.001
        let b2 = 0.0005
        let a1 = -1.979
        let a2 = 0.98

        return [b0, b1, b2, a1, a2]
    }()
    
    static let biquadHighPass: [Double] = {
        let b0 = 0.805
        let b1 = -1.61
        let b2 = 0.805
        let a1 = -1.572
        let a2 = 0.68
        
        return [b0, b1, b2, a1, a2]
    }()
    
    static let dctHighPass: [Float] = {
        return interpolatedVectorFrom(magnitudes:  [0,   0,   1,    1],
                                      indices:     [0, 340, 350, 1024],
                                      count: sampleCount)
    }()
    
    static let dctLowPass: [Float] = {
        return interpolatedVectorFrom(magnitudes:  [1,   1,   0,   0],
                                      indices:     [0, 200, 210, 1024],
                                      count: sampleCount)
    }()

    static let dctBandPass: [Float] = {
        return interpolatedVectorFrom(magnitudes:  [0,   0,   1,   1,   0,    0],
                                      indices:     [0, 290, 300, 380, 390, 1024],
                                      count: sampleCount)
    }()
    
    static let dctBandStop: [Float] = {
        return interpolatedVectorFrom(magnitudes:  [1,   1,   0,   0,   1,    1],
                                      indices:     [0, 290, 300, 380, 390, 1024],
                                      count: sampleCount)
    }()
    
    static func interpolatedVectorFrom(magnitudes: [Float],
                                       indices: [Float],
                                       count: Int) -> [Float] {
        assert(magnitudes.count == indices.count,
               "`magnitudes.count` must equal `indices.count`.")
        
        var c = [Float](repeating: 0,
                        count: count)
        
        let stride = vDSP_Stride(1)
        
        vDSP_vgenp(magnitudes, stride,
                   indices, stride,
                   &c, stride,
                   vDSP_Length(count),
                   vDSP_Length(magnitudes.count))
        
        return c
    }
}
