/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for various game-specific functionality on SCNNode.
*/

import Foundation
import SceneKit
import os.log

/**
 * Protect animation on SCNTransaction from multiple threads, can be nested too.
 * Nested transactions all start at the same time as their enclosing scope
 * and are limited in duration by the outer block.  This is useful for animating
 * two things at once with different timings. For example:
 *
 *   SCNTransaction.animate(duration: 1.0) {
 *     node.simdWorldTransform = ...
 *     node.opacity = ...
 *   }
 *
 * Completion blocks run after the animationBlock and let you sequence animation.
 * Since this is more common, an example is shown below:
 *
 *   SCNTransaction.animate(duration: 1.0, animations: {
 *      node.simdWorldTransform = ...    // start at 0, end at 1s
 *   }, completion: {
 *      SCNTransaction.animation(2.0, animations: {
 *          node.simdWorldTransform = ...  // start at 1, end at 3s
 *      }, completion: {
 *          // you can use this to sequence further blocks
 *          foo = true
 *      })
 *   })
*/
extension SCNTransaction {
    static func animate(duration: TimeInterval,
                        animations: (() -> Void)) {
        animate(duration: duration, animations: animations, completion: nil)
    }
    static func animate(duration: TimeInterval,
                        animations: (() -> Void),
                        completion: (() -> Void)? = nil) {
        lock(); defer { unlock() }
        begin(); defer { commit() }
        
        animationDuration = duration
        completionBlock = completion
        animations()
    }
}

extension SCNNode {

    var gameObject: GameObject? {
        get { return entity as? GameObject }
        set { entity = newValue }
    }

    func nearestParentGameObject() -> GameObject? {
        if let result = gameObject { return result }
        if let parent = parent { return parent.nearestParentGameObject() }
        return nil
    }

    func findNodeWithPhysicsBody() -> SCNNode? {
        return findNodeWithPhysicsBodyHelper(node: self)
    }
    
    func findNodeWithGeometry() -> SCNNode? {
        return findNodeWithGeometryHelper(node: self)
    }
    
    var team: Team {
        var parent = self.parent
        while let current = parent {
            if current.name == "_teamA" {
                return .teamA
            } else if current.name == "_teamB" {
                return .teamB
            }
            parent = current.parent
        }
        return .none
    }

    var typeIdentifier: String? {
        if let name = name, !name.hasPrefix("_") {
            return name.split(separator: "_").first.map { String($0) }
        } else {
            return nil
        }
    }
    
    // Returns the size of the horizontal parts of the node's bounding box.
    // x is the width, y is the depth.
    var horizontalSize: SIMD2<Float> {
        let (minBox, maxBox) = simdBoundingBox

        // Scene is y-up, horizontal extent is calculated on x and z
        let sceneWidth = abs(maxBox.x - minBox.x)
        let sceneLength = abs(maxBox.z - minBox.z)
        return SIMD2<Float>(sceneWidth, sceneLength)
    }
    
    private func findNodeWithPhysicsBodyHelper(node: SCNNode) -> SCNNode? {
        if node.physicsBody != nil {
            return node
        }
        for child in node.childNodes {
            if shouldContinueSpecialNodeSearch(node: child) {
                if let childWithPhysicsBody = findNodeWithPhysicsBodyHelper(node: child) {
                    return childWithPhysicsBody
                }
            }
        }
        return nil
    }
    
    private func findNodeWithGeometryHelper(node: SCNNode) -> SCNNode? {
        if node.geometry != nil {
            return node
        }
        for child in node.childNodes {
            if shouldContinueSpecialNodeSearch(node: child) {
                if let childWithGeosBody = findNodeWithGeometryHelper(node: child) {
                    return childWithGeosBody
                }
            }

        }
        return nil
    }
    
    private func shouldContinueSpecialNodeSearch(node: SCNNode) -> Bool {
        // end geo + physics search when a system collection is found
        if let isEndpoint = node.value(forKey: "isEndpoint") as? Bool, isEndpoint {
            return false
        }
        
        return true
    }

    func hitTestWithSegment(from pointA: SIMD3<Float>, to pointB: SIMD3<Float>, options: [String: Any]? = nil) -> [SCNHitTestResult] {
        return hitTestWithSegment(from: SCNVector3(pointA), to: SCNVector3(pointB), options: options)
    }
    var simdBoundingBox: (min: SIMD3<Float>, max: SIMD3<Float>) {
        get {
            return (SIMD3<Float>(boundingBox.min), SIMD3<Float>(boundingBox.max))
        }
        set {
            boundingBox = (min: SCNVector3(newValue.min), max: SCNVector3(newValue.max))
        }
    }

    func resizeParticleSystems(scale: Float) {
        guard let particleSystems = particleSystems else { return }
        // Resize the whole particle system for all particle systems under this node
        for particleSystem in particleSystems {
            particleSystem.particleSize = CGFloat(scale) * particleSystem.particleSize
            particleSystem.particleVelocity = CGFloat(scale) * particleSystem.particleVelocity
            particleSystem.particleVelocityVariation = CGFloat(scale) * particleSystem.particleVelocityVariation
        }
    }
    
    func resetParticleSystems() {
        if let particleSystems = particleSystems {
            for particleSystem in particleSystems {
                particleSystem.reset()
            }
        }
    }

    func resetChildPhysics() {
        physicsBody?.resetTransform()
        childNodes.forEach { $0.resetChildPhysics() }
    }
    
    static func loadSCNAsset(modelFileName: String) -> SCNNode {
        let assetPaths = [
            "gameassets.scnassets/models/",
            "gameassets.scnassets/blocks/",
            "gameassets.scnassets/projectiles/",
            "gameassets.scnassets/catapults/",
            "gameassets.scnassets/levels/",
            "gameassets.scnassets/effects/"
            ]
        
        let assetExtensions = [
            "scn",
            "scnp"
        ]
        
        var nodeRefSearch: SCNReferenceNode?
        for path in assetPaths {
            for ext in assetExtensions {
                if let url = Bundle.main.url(forResource: path + modelFileName, withExtension: ext) {
                    nodeRefSearch = SCNReferenceNode(url: url)
                    if nodeRefSearch != nil { break }
                }
            }
            if nodeRefSearch != nil { break }
        }

        guard let nodeRef = nodeRefSearch else {
            fatalError("couldn't load \(modelFileName)")
        }
        
        // this does the load, default policy is load immediate
        nodeRef.load()
        
        // log an error if geo not nested under a physics shape
        guard let node = nodeRef.childNodes.first else {
            fatalError("model \(modelFileName) has no child nodes")
        }
        if nodeRef.childNodes.count > 1 {
            os_log(.error, "model %s should have a single root node", modelFileName)
        }
        
        // walk down the scenegraph and update all children
        node.fixMaterials()
        
        return node
    }
    
    func setNodeToOccluder() {
        let material = SCNMaterial(diffuse: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        material.colorBufferWriteMask = []
        material.writesToDepthBuffer = true
        
        guard let geometry = geometry else { fatalError("Node has no geometry") }
        geometry.materials = [material]
        renderingOrder = -10
        castsShadow = false
    }
    
    func setNodeToAlwaysInFront(recursively: Bool) {
        if let geometry = geometry {
            for material in geometry.materials {
                material.writesToDepthBuffer = true
                material.readsFromDepthBuffer = false
            }
        }
        renderingOrder = 100
        castsShadow = false
        
        guard recursively else { return }
        for child in childNodes {
            child.setNodeToAlwaysInFront(recursively: recursively)
        }
    }
    
    func parentWithPrefix(prefix: String) -> SCNNode? {
        if let name = name, name.hasPrefix(prefix) {
            return self
        } else if let parent = parent {
            return parent.parentWithPrefix(prefix: prefix)
        } else {
            return nil
        }
    }
    
    func playAllAnimations() {
        enumerateChildNodes { (child, stop) in
            for key in child.animationKeys {
                guard let animationPlayer = child.animationPlayer(forKey: key) else { continue }
                animationPlayer.play()
            }
        }
    }
    
    func stopAllAnimations() {
        enumerateChildNodes { (child, stop) in
            for key in child.animationKeys {
                guard let animationPlayer = child.animationPlayer(forKey: key) else { continue }
                animationPlayer.stop()
            }
        }
    }
    
    func calculateMassFromDensity(name: String, density: Float) {
        if let physicsBody = physicsBody {
    
            // our naming convention lets us parse the shape geometry
            let bounds = (simdBoundingBox.max - simdBoundingBox.min)
            // calculate as a cylinder going up
            if name.hasPrefix("block_cylinder") {
                let radius = bounds.x / 2.0
                let mass = .pi * radius * radius * bounds.y
                physicsBody.mass = CGFloat(density * mass)
            } else if name.hasPrefix("block_halfCylinder") { // half cylinder going up
                let radius = min(bounds.x, bounds.z)
                let mass = .pi * radius * radius * bounds.y / 2.0
                physicsBody.mass = CGFloat(density * mass)
            } else if name.hasPrefix("block_quarterCylinder") { // this is a cylinder lying sideways
                let radius = min(bounds.y, bounds.z)
                let mass = .pi * radius * radius * bounds.x / 4.0
                physicsBody.mass = CGFloat(density * mass)
            } else {
                // for now, treat as box shape
                physicsBody.mass = CGFloat(density * bounds.x * bounds.y * bounds.z)
            }
        }
    }
}
