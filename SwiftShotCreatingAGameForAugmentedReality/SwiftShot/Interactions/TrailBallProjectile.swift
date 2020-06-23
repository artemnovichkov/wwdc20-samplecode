/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Draws a motion trail behind the ball.
*/

import Foundation
import SceneKit

extension SIMD4 where Scalar == Float {
    init(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.init(Float(red), Float(green), Float(blue), Float(alpha))
    }
}

extension SCNGeometrySource {
    convenience init(vertices: [SIMD3<Float>]) {
        self.init(vertices: vertices.map(SCNVector3.init))
    }
    convenience init(colors: [SIMD4<Float>]) {
        
        let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
        self.init(data: colorData,
                  semantic: .color,
                  vectorCount: colors.count,
                  usesFloatComponents: true,
                  componentsPerVector: 4,
                  bytesPerComponent: MemoryLayout.size(ofValue: colors[0].x),
                  dataOffset: 0,
                  dataStride: MemoryLayout.stride(ofValue: colors[0]))
    }

}

extension Array {
    mutating func removeAllButLast(_ countToKeep: Index) {
        let countToRemove = Swift.max(count - countToKeep, 0)
        removeFirst(countToRemove)
    }
}

class TrailBallProjectile: Projectile {
    // default values the result of a vast user study.
    static let ballSize: Float = 0.275
    static let defaultTrailWidth: Float = 0.5 // Default trail with with ball size as the unit (1.0 represents same width as the ball)
    static let defaultTrailLength: Int = 108

    let trailNode = SCNNode()
    let trailMat = SCNMaterial()
    let epsilon: Float = 1.19209290E-07 // upper limit on float rounding error
    
    var worldPositions: [SIMD3<Float>] = []

    var trailHalfWidth: Float {
        return (UserDefaults.standard.trailWidth ?? TrailBallProjectile.defaultTrailWidth) * TrailBallProjectile.ballSize * 0.5
    }
    var maxTrailPositions: Int { return UserDefaults.standard.trailLength ?? TrailBallProjectile.defaultTrailLength }
    var trailShouldNarrow: Bool { return UserDefaults.standard.tailShouldNarrow }
    
    override func launch(velocity: GameVelocity, lifeTime: TimeInterval, delegate: ProjectileDelegate) {
        super.launch(velocity: velocity, lifeTime: lifeTime, delegate: delegate)

        addTrail()
    }

    override func onSpawn() {
        super.onSpawn()
        addTrail()
    }

    override func despawn() {
        super.despawn()
        removeTrail()
    }

    private func addTrail() {
        guard let physicsNode = physicsNode else { return }
        trailNode.castsShadow = false
        if let physicsBody = physicsNode.physicsBody {
            physicsBody.angularDamping = 1.0
        }
        
        guard let delegate = delegate else { return }
        delegate.addNodeToLevel(node: trailNode)
    }

    private func removeTrail() {
        trailNode.removeFromParentNode()
    }
    
    private var tempWorldPositions = [SIMD3<Float>]()
    private var colors = [SIMD4<Float>]()

    override func onDidApplyConstraints(renderer: SCNSceneRenderer) {
        let frameSkips = 3
        guard (GameTime.frameCount + index) % frameSkips == 0 else { return }
        guard let physicsNode = physicsNode else { return }
        
        if worldPositions.count > (maxTrailPositions / frameSkips) {
            removeVerticesPair()
        }
        
        let pos = physicsNode.presentation.simdWorldPosition
    
        var trailDir: SIMD3<Float>
        if let prevPos = worldPositions.last {
            trailDir = pos - prevPos
            
            let lengthSquared = length_squared(trailDir)
            if lengthSquared < epsilon {
                removeVerticesPair()
                updateColors()
                let localPositions = tempWorldPositions.map { trailNode.presentation.simdConvertPosition($0, from: nil) }
                trailNode.presentation.geometry = createTrailMesh(positions: localPositions, colors: colors)
                return
            }
            trailDir = normalize(trailDir)
        } else {
            trailDir = objectRootNode.simdWorldFront
        }
    
        var right = cross(SIMD3<Float>(0.0, 1.0, 0.0), trailDir)
        right = normalize(right)
        let scale: Float = 1.0 //Float(i - 1) / worldPositions.count
        var halfWidth = trailHalfWidth
        if trailShouldNarrow {
            halfWidth *= scale
        }
        let u = pos + right * halfWidth
        let v = pos - right * halfWidth
        
        worldPositions.append(pos)
        tempWorldPositions.append(u)
        tempWorldPositions.append(v)
        
        colors.append(SIMD4<Float>())
        colors.append(SIMD4<Float>())
        
        updateColors()
        let localPositions = tempWorldPositions.map { trailNode.presentation.simdConvertPosition($0, from: nil) }
        trailNode.presentation.geometry = createTrailMesh(positions: localPositions, colors: colors)
    }
    
    private func removeVerticesPair() {
        worldPositions.removeFirst()
        tempWorldPositions.removeFirst(2)
        colors.removeFirst(2)
    }
    
    private func updateColors() {
        let baseColor = SIMD4<Float>(color: team.color)
        for i in 0..<colors.count {
            let scale = Float(i) / Float(colors.count)
            colors[i] = baseColor * scale
        }
    }

    func createTrailMesh(positions: [SIMD3<Float>], colors: [SIMD4<Float>]) -> SCNGeometry? {
        guard positions.count >= 4 else { return nil }
        let posSource = SCNGeometrySource(vertices: positions)
        let colorSource = SCNGeometrySource(colors: colors)

        let element = SCNGeometryElement(indices: Array(0..<UInt16(positions.count)), primitiveType: .triangleStrip)

        let trailMesh = SCNGeometry(sources: [posSource, colorSource], elements: [element])
        guard let material = trailMesh.firstMaterial else { fatalError("created geometry without material") }
        material.isDoubleSided = true
        material.lightingModel = .constant
        material.blendMode = .add
        material.writesToDepthBuffer = false

        return trailMesh
    }

}
