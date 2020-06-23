/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Class for applying saturation and luma gamma changes to images.
*/

import Cocoa
import Accelerate
import Combine

class YCbCrAdjustment: ObservableObject {
    
    var cancellableSaturation: AnyCancellable?
    var cancellableLumaGamma: AnyCancellable?
    
    @Published var saturation: Float = 1
    @Published var lumaGamma: Float = 1
    
    @Published var useLinear: Bool {
        didSet {
            argbSourceBuffer = YCbCrAdjustment.bufferFromImage(sourceCGImage,
                                                               format: format,
                                                               useLinear: useLinear)
            convertArgbToYpCbCr()
            applyAdjustment()
        }
    }
    
    @Published var outputImage: CGImage
    
    init?(image: NSImage) {
        self.image = image
        
        var rect = CGRect(origin: .zero, size: image.size)
        
        guard
            let sourceCGImage = image.cgImage(forProposedRect: &rect,
                                              context: nil,
                                              hints: nil),
            let format = vImage_CGImageFormat(cgImage: sourceCGImage) else {
                return nil
        }
        
        self.sourceCGImage = sourceCGImage
        self.format = format
        
        outputImage = sourceCGImage
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        let useLinear = true

        self.useLinear = useLinear
        argbSourceBuffer = YCbCrAdjustment.bufferFromImage(sourceCGImage,
                                                           format: format,
                                                           useLinear: useLinear)
        
        convertArgbToYpCbCr()

        cancellableSaturation = $saturation
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { _ in
                self.applyAdjustment()
            }
        
        cancellableLumaGamma = $lumaGamma
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { _ in
                self.applyAdjustment()
            }
    }

    public func reset() {
        saturation = 1
        lumaGamma = 1
    }
    
    let width: Int
    let height: Int
    
    let image: NSImage
    let sourceCGImage: CGImage
    let format: vImage_CGImageFormat
    
    private var pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 0,
                                                     CbCr_bias: 128,
                                                     YpRangeMax: 255,
                                                     CbCrRangeMax: 255,
                                                     YpMax: 255,
                                                     YpMin: 0,
                                                     CbCrMax: 255,
                                                     CbCrMin: 0)
    
    private var argbToYpCbCr: vImage_ARGBToYpCbCr {
        var outInfo = vImage_ARGBToYpCbCr()
        
        vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_709_2,
                                                      &pixelRange,
                                                      &outInfo,
                                                      kvImageARGB8888,
                                                      kvImage420Yp8_CbCr8,
                                                      vImage_Flags(kvImageNoFlags))
        return outInfo
    }
    
    private var ypCbCrToARGB: vImage_YpCbCrToARGB {
        var outInfo = vImage_YpCbCrToARGB()
        
        vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_709_2,
                                                      &pixelRange,
                                                      &outInfo,
                                                      kvImage420Yp8_CbCr8,
                                                      kvImageARGB8888,
                                                      vImage_Flags(kvImageNoFlags))
        
        return outInfo
    }
    
    static func bufferFromImage(_ cgImage: CGImage,
                                format: vImage_CGImageFormat,
                                useLinear: Bool) -> vImage_Buffer {
        guard
            var source = try? vImage_Buffer(cgImage: cgImage,
                                            format: format) else {
                                                fatalError("Unable to create source buffer.")
        }
        
        if useLinear {
            try? source.remap(.sRGBToLinear,
                              componentCount: format.componentCount)
        }
        
        return source
    }
    
    func convertArgbToYpCbCr() {
        _ = withUnsafePointer(to: argbSourceBuffer) { src in
            withUnsafePointer(to: argbToYpCbCr) { info in
                vImageConvert_ARGB8888To420Yp8_CbCr8(src,
                                                     &ycbcrBuffers.yp,
                                                     &ycbcrBuffers.cbcr,
                                                     info,
                                                     [3, 2, 1, 0],
                                                     vImage_Flags(kvImagePrintDiagnosticsToConsole))
            }
        }
    }
    
    private var argbSourceBuffer: vImage_Buffer
    
    lazy private var ycbcrBuffers: (yp: vImage_Buffer, cbcr: vImage_Buffer) = {
        guard
            var ypSource = try? vImage_Buffer(width: width,
                                              height: height,
                                              bitsPerPixel: 8),
            var cbcrSource = try? vImage_Buffer(width: Int(argbSourceBuffer.width),
                                                height: Int(argbSourceBuffer.height / 2),
                                                bitsPerPixel: 8) else {
                                                    fatalError("Unable to create YCbCr buffers.")
        }
        return (yp: ypSource, cbcr: cbcrSource)
    }()
    
    private lazy var ypDestination: vImage_Buffer = {
        guard let buffer = try? vImage_Buffer(width: self.width,
                                              height: self.height,
                                              bitsPerPixel: 8) else {
                                                fatalError("Unable to create `ypDestination`.")
                                                
        }
        return buffer
    }()
    
    private lazy var cbcrDestination: vImage_Buffer = {
        guard let buffer = try? vImage_Buffer(width: self.width,
                                              height: self.height / 2,
                                              bitsPerPixel: 8) else {
                                                fatalError("Unable to create `cbcrDestination`.")
                                                
        }
        return buffer
    }()
    
    private lazy var argbDestination: vImage_Buffer = {
        guard let buffer = try? vImage_Buffer(width: self.width,
                                              height: self.height,
                                              bitsPerPixel: 32) else {
                                                fatalError("Unable to create `argbDestination`.")
                                                
        }
        return buffer
    }()
    
    private lazy var gammaDestination: vImage_Buffer = {
        guard let buffer = try? vImage_Buffer(width: Int(ycbcrBuffers.cbcr.width),
                                              height: Int(ycbcrBuffers.cbcr.height),
                                              bitsPerPixel: 32) else {
                                                fatalError("Unable to create `gammaDestination`.")
                                                
        }
        return buffer
    }()
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private func applyAdjustment() {
        self.semaphore.wait()
        let result = self.applyAdjustmentAsync()
        
        DispatchQueue.main.async {
            self.outputImage = result
            self.semaphore.signal()
        }
    }
    
    private func applyAdjustmentAsync() -> CGImage {
        if saturation > 1 {
            applyGammaToCbCr(gamma: 1 / saturation)
        } else {
            applyLinearToCbCr(saturation: saturation)
        }
        
        applyGammaToLuma(lumaGamma: lumaGamma)
        
        _ = withUnsafePointer(to: ypCbCrToARGB) { info in
            vImageConvert_420Yp8_CbCr8ToARGB8888(&ypDestination,
                                                 &cbcrDestination,
                                                 &argbDestination,
                                                 info,
                                                 [3, 2, 1, 0],
                                                 255,
                                                 vImage_Flags(kvImagePrintDiagnosticsToConsole))
        }
        
        if useLinear {
            try? argbDestination.remap(.linearToSRGB,
                                       componentCount: format.componentCount)
        }
        
        guard let result = try? argbDestination.createCGImage(format: format) else {
            fatalError("Unable to create output image.")
        }
        
        return result
    }
    
    private func applyGammaToLuma(lumaGamma: Float) {
        _ = withUnsafePointer(to: ycbcrBuffers.yp) { src in
            vImagePiecewiseGamma_Planar8(src,
                                         &ypDestination,
                                         [1, 0, 0],
                                         lumaGamma,
                                         [1, 0],
                                         0,
                                         vImage_Flags(kvImageNoFlags))
        }
    }
    
    private func applyLinearToCbCr(saturation: Float) {
        var preBias: Int16 = -128
        let divisor: Int32 = 0x1000
        var postBias: Int32 = 128 * divisor
        
        var matrix = [ Int16(saturation * Float(divisor)) ]
        
        withUnsafePointer(to: &cbcrDestination) { dest in
            withUnsafePointer(to: ycbcrBuffers.cbcr) { src in
                var sources: UnsafePointer<vImage_Buffer>? = src
                var destinations: UnsafePointer<vImage_Buffer>? = dest
                
                vImageMatrixMultiply_Planar8(&sources,
                                             &destinations,
                                             1,
                                             1,
                                             &matrix,
                                             divisor,
                                             &preBias,
                                             &postBias,
                                             vImage_Flags(kvImageNoFlags))
            }
        }
    }
    
    private func applyGammaToCbCr(gamma: Float) {
        let gammaFunction = vImageCreateGammaFunction(gamma,
                                                      Int32(kvImageGamma_UseGammaValue),
                                                      vImage_Flags(kvImageNoFlags))
        defer {
            vImageDestroyGammaFunction(gammaFunction)
        }
        
        _ = withUnsafePointer(to: ycbcrBuffers.cbcr) { cbcrSource in
            vImageConvert_Planar8toPlanarF(cbcrSource,
                                           &gammaDestination,
                                           1, -1,
                                           vImage_Flags(kvImageNoFlags))
        }
        
        vImageGamma_PlanarF(&gammaDestination,
                            &gammaDestination,
                            gammaFunction,
                            0)
        
        vImageConvert_PlanarFtoPlanar8(&gammaDestination,
                                       &cbcrDestination,
                                       1, -1,
                                       vImage_Flags(kvImageNoFlags))
    }
}
