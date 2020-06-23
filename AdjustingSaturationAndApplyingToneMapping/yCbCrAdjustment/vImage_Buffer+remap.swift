/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension to vImage_Buffer to remap between sRGB and linear.
*/

import Accelerate

extension vImage_Buffer {
    
    enum Remap {
        case linearToSRGB
        case sRGBToLinear
        
        var gammaType: Int32 {
            let gammaType: Int
            
            switch self {
                case .linearToSRGB:
                    gammaType = kvImageGamma_sRGB_forward_half_precision
                case .sRGBToLinear:
                    gammaType = kvImageGamma_sRGB_reverse_half_precision
            }
            return Int32(gammaType)
        }
    }

    mutating func remap(_ remap: Remap, componentCount: Int) throws {
        
        let gammaFunction = vImageCreateGammaFunction(0,
                                                      remap.gammaType,
                                                      vImage_Flags(kvImageNoFlags))
        defer {
            vImageDestroyGammaFunction(gammaFunction)
        }
        
        guard
            let floatBuffer = try? vImage_Buffer(width: Int(self.width),
                                                 height: Int(self.height),
                                                 bitsPerPixel: 32 * UInt32(componentCount)) else {
                                                    throw vImage.Error(vImageError: kvImageInternalError)
        }
        
        defer {
            floatBuffer.free()
        }
        
        var planarBuffer = vImage_Buffer(data: self.data,
                                         height: self.height,
                                         width: self.width * UInt(componentCount),
                                         rowBytes: self.rowBytes)
        
        var planarFloatBuffer = vImage_Buffer(data: floatBuffer.data,
                                              height: floatBuffer.height,
                                              width: floatBuffer.width * UInt(componentCount),
                                              rowBytes: floatBuffer.rowBytes)
        
        var error = kvImageNoError
        
        error = vImageConvert_Planar8toPlanarF(&planarBuffer,
                                               &planarFloatBuffer,
                                               1, 0,
                                               vImage_Flags(kvImageNoFlags))
        
        if error != kvImageNoError {
            throw vImage.Error(vImageError: error)
        }
        
        error = vImageGamma_PlanarF(&planarFloatBuffer,
                                    &planarFloatBuffer,
                                    gammaFunction,
                                    vImage_Flags(kvImageNoFlags))
        
        if error != kvImageNoError {
            throw vImage.Error(vImageError: error)
        }
        
        error = vImageConvert_PlanarFtoPlanar8(&planarFloatBuffer,
                                               &planarBuffer,
                                               1, 0,
                                               vImage_Flags(kvImageNoFlags))
        
        if error != kvImageNoError {
            throw vImage.Error(vImageError: error)
        }
    }
}
