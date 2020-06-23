/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Connects nodes loaded from separate resources with physics joints based on node names.
*/

import Foundation
import GameplayKit

extension SCNNode {
    func hasConstraints() -> Bool {
        let balljoints = findAllJoints(prefix: ConstrainHierarchyComponent.jointName)
        let hingeJoints = findAllJoints(prefix: ConstrainHierarchyComponent.hingeName)
        return !(balljoints.isEmpty && hingeJoints.isEmpty)
    }
    
    func findAllJoints(prefix: String) -> [SCNNode] {
        var array = [SCNNode]()
        if let physicsNode = findNodeWithPhysicsBody() {
            // ball joints have the correct prefix and are first generation children of entity node
            for child in physicsNode.childNodes {
                if let name = child.name,
                    name.hasPrefix(prefix) {
                    array.append(child)
                }
            }
        }
        
        return array
    }
}

// goes through hierarchy of node, starting at parent, and checks for constraint_ball nodes
// which it tries to attach to constraint_socket_nodes with the same suffix.
class ConstrainHierarchyComponent: GKComponent, PhysicsBehaviorComponent {

    static let hingeName = "constraint_hinge"
    static let jointName = "constraint_ball"
    static let socketName = "constraint_attach"
    private let searchDist = Float(0.5)
    private var joints = [SCNPhysicsBehavior]()
    var behaviors: [SCNPhysicsBehavior] {
        return joints
    }

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // go through hierarchy, find all socket nodes + their corresponding join locations
    func initBehavior(levelRoot: SCNNode, world: SCNPhysicsWorld) {
        guard let entity = entity as? GameObject else { return }
        let root = entity.objectRootNode
        guard let systemRoot = root.parentWithPrefix(prefix: "_system") else { return }
        
        // search for ball constraint with name constraint_ball_
        let ballArray = root.findAllJoints(prefix: ConstrainHierarchyComponent.jointName)
        for ballSocket in ballArray {
            guard let physicsNode = entity.physicsNode, let physicsBody = physicsNode.physicsBody else { continue }
            physicsBody.resetTransform()
            let socketOffset = ballSocket.simdConvertPosition(SIMD3<Float>(repeating: 0), to: systemRoot)
            
            // find in root first
            let (closestNode, _) = findAttachNodeNearPoint(system: systemRoot, node: systemRoot, point: socketOffset, tolerance: searchDist)
            if let socketNode = closestNode,
                let socketEntityNode = socketNode.nearestParentGameObject(),
                let attachPhysics = socketEntityNode.physicsNode,
                let attachBody = attachPhysics.physicsBody {
                attachBody.resetTransform()
                
                createBallJoint(source: physicsBody,
                                sourceOffset: ballSocket.convertPosition(SCNVector3Zero, to: physicsNode),
                                dest: attachBody,
                                destOffset: socketNode.convertPosition(SCNVector3Zero, to: attachPhysics))
                
            }
        }
            
        let hingeArray = root.findAllJoints(prefix: ConstrainHierarchyComponent.hingeName)
        for hingeJoint in hingeArray {
            guard let physicsNode = entity.physicsNode, let physicsBody = physicsNode.physicsBody else { continue }
            physicsBody.resetTransform()
            let hingeOffset = hingeJoint.simdConvertPosition(SIMD3<Float>(repeating: 0), to: systemRoot)
            
            // find in root first
            let (closestNode, _) = findAttachNodeNearPoint(system: systemRoot, node: systemRoot, point: hingeOffset, tolerance: searchDist)
            if let attachNode = closestNode,
                let attachEntityNode = attachNode.nearestParentGameObject(),
                let attachPhysics = attachEntityNode.physicsNode,
                let attachBody = attachPhysics.physicsBody {
                
                    attachBody.resetTransform()
                
                    createHingeJoint(source: physicsBody,
                                sourceAxis: hingeJoint.convertVector(SCNVector3Make(0.0, 1.0, 0.0), to: physicsNode),
                                sourceAnchor: hingeJoint.convertPosition(SCNVector3Zero, to: physicsNode),
                                dest: attachBody,
                                destAxis: hingeJoint.convertVector(SCNVector3Make(0.0, 1.0, 0.0), to: attachPhysics),
                                destAnchor: attachNode.convertPosition(SCNVector3Zero, to: attachPhysics))
                
            }
        }
        
        for joint in joints {
            world.addBehavior(joint)
        }
    }
    
    private func createBallJoint(source: SCNPhysicsBody, sourceOffset: SCNVector3, dest: SCNPhysicsBody, destOffset: SCNVector3) {
        let joint = SCNPhysicsBallSocketJoint(bodyA: source, anchorA: sourceOffset, bodyB: dest, anchorB: destOffset)
        joints.append(joint)
    }
    
    private func createHingeJoint(source: SCNPhysicsBody,
                                  sourceAxis: SCNVector3,
                                  sourceAnchor: SCNVector3,
                                  dest: SCNPhysicsBody,
                                  destAxis: SCNVector3,
                                  destAnchor: SCNVector3) {
        let joint = SCNPhysicsHingeJoint(bodyA: source, axisA: sourceAxis, anchorA: sourceAnchor, bodyB: dest, axisB: destAxis, anchorB: destAnchor)
        joints.append(joint)
    }
    
    private func findAttachNodeNearPoint(system: SCNNode, node: SCNNode, point: SIMD3<Float>, tolerance: Float) -> (SCNNode?, Float) {
        var currentTolerance = tolerance
        var currentClosestNode: SCNNode? = nil
        if let name = node.name,  // if this object has a socket node near ball node, then use it
            name.hasPrefix(ConstrainHierarchyComponent.socketName) {
            let attachOffset = node.simdConvertPosition(SIMD3<Float>(repeating: 0), to: system)
            let distance = length(point - attachOffset)
            if distance < currentTolerance {
                currentTolerance = distance
                currentClosestNode = node
            }
        }
        
        for child in node.childNodes {
            let (socketNode, distance) = findAttachNodeNearPoint(system: system, node: child, point: point, tolerance: currentTolerance)
            if socketNode != nil {
                currentTolerance = distance
                currentClosestNode = socketNode
            }
        }
        
        return (currentClosestNode, currentTolerance)
    }
}
