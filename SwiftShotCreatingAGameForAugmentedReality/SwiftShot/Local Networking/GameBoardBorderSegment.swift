/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Corner segments for the game board's border UI.
*/

import SceneKit

extension GameBoard {
    enum Corner: CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        var u: Float {
            switch self {
            case .topLeft:     return -1
            case .topRight:    return 1
            case .bottomLeft:  return -1
            case .bottomRight: return 1
            }
        }
        
        var v: Float {
            switch self {
            case .topLeft:     return -1
            case .topRight:    return -1
            case .bottomLeft:  return 1
            case .bottomRight: return 1
            }
        }
    }
    
    enum Alignment: CaseIterable {
        case horizontal
        case vertical
        
        func xOffset(for size: CGSize) -> Float {
            switch self {
            case .horizontal: return Float(size.width / 2 - BorderSegment.thickness) / 2
            case .vertical:   return Float(size.width / 2)
            }
        }
        
        func yOffset(for size: CGSize) -> Float {
            switch self {
            case .horizontal: return Float(size.height / 2 - BorderSegment.thickness / 2)
            case .vertical:   return Float(size.height / 2) / 2
            }
        }
    }
    
    class BorderSegment: SCNNode {
        
        // MARK: - Configuration & Initialization
        
        /// Thickness of the border lines.
        static let thickness: CGFloat = 0.012
        
        /// The scale of segment's length when in the open state
        static let openScale: Float = 0.4
        
        let corner: Corner
        let alignment: Alignment
        let plane: SCNPlane
        
        init(corner: Corner, alignment: Alignment, borderSize: CGSize) {
            self.corner = corner
            self.alignment = alignment
            
            plane = SCNPlane(width: BorderSegment.thickness, height: BorderSegment.thickness)
            self.borderSize = borderSize
            super.init()
            
            let material = plane.firstMaterial!
            material.diffuse.contents = GameBoard.borderColor
            material.emission.contents = GameBoard.borderColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            geometry = plane
            opacity = 0.8
        }
        
        var borderSize: CGSize {
            didSet {
                switch alignment {
                case .horizontal: plane.width = borderSize.width / 2
                case .vertical:   plane.height = borderSize.height / 2
                }
                simdScale = SIMD3<Float>(repeating: 1)
                simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize),
                                      corner.v * alignment.yOffset(for: borderSize),
                                      0)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("\(#function) has not been implemented")
        }
        
        // MARK: - Animating Open/Closed
        
        func open() {
            var offset = SIMD2<Float>()
            if alignment == .horizontal {
                simdScale = SIMD3<Float>(BorderSegment.openScale, 1, 1)
                offset.x = (1 - BorderSegment.openScale) * Float(borderSize.width) / 4
            } else {
                simdScale = SIMD3<Float>(1, BorderSegment.openScale, 1)
                offset.y = (1 - BorderSegment.openScale) * Float(borderSize.height) / 4
            }
            
            simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize) + corner.u * offset.x,
                                  corner.v * alignment.yOffset(for: borderSize) + corner.v * offset.y,
                                  0)
        }
        
        func close() {
            simdScale = SIMD3<Float>(repeating: 1)
            simdPosition = SIMD3<Float>(corner.u * alignment.xOffset(for: borderSize),
                                  corner.v * alignment.yOffset(for: borderSize),
                                  0)
        }
    }
}
