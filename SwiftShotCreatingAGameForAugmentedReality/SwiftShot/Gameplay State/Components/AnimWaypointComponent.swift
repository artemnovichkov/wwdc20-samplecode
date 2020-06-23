/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Component that lets an animation move along a predefined path of points in the level
*/

import Foundation

import GameplayKit
struct Waypoint {
    var pos: SIMD3<Float>
    var tangent: SIMD3<Float>
    var rot: simd_quatf
    var time: TimeInterval
}

let waypointPrefix = "_waypoint"

class AnimWaypointComponent: GKComponent {
    private var wayPoints: [Waypoint] = []
    private var speed: Double = 1.0
    private var currentTime: TimeInterval = 0.0
    private var currentFrame: Int = 0
    private let node: SCNNode
    var hasWaypoints: Bool {
        return wayPoints.count > 1
    }
    
    init(node: SCNNode, properties: [String: Any]) {
        self.node = node
        super.init()
        
        if let speed = properties["speed"] as? Double {
            self.speed = speed
        }
        
        // find all waypoints
        initWaypoints(node: node)
        calculateTangents()
        
        // does this animation support random start times?
        if let random = properties["random"] as? Bool, random, let last = wayPoints.last {
            currentTime = drand48() * last.time
        }
        
        // do we want to start at a particular percentage along curve?
        if let phase = properties["phase"] as? Double, let last = wayPoints.last {
            let desiredPhase: Double = clamp(phase, 0.0, 1.0)
            currentTime = desiredPhase * last.time
        }
        
        // do we want to start at a specific point in time?
        if let offset = properties["offset"] as? Double, let last = wayPoints.last {
            currentTime = offset * last.time
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calcCurrentFrameIndex() {
        guard let last = wayPoints.last else { return }
        
        // loop if we are past endpoint
        while currentTime > last.time, last.time > 0 {
            currentTime -= last.time
        }
        
        // update frame when past time value
        for i in 0..<wayPoints.count {
            if currentTime > wayPoints[i].time {
                currentFrame = i
            } else {
                return
            }
        }
    }
    
    private func initWaypoints(node: SCNNode) {
        // find start of animation group system
        guard let systemRoot = node.parentWithPrefix(prefix: "_system") else { return }
        
        // find all of the waypoints
        iterateForWaypoints(node: systemRoot)
        
        // close the loop
        guard let first = wayPoints.first else { return }
        let waypoint = Waypoint(pos: first.pos,
                                tangent: SIMD3<Float>(repeating: 0),
                                rot: first.rot,
                                time: Double(wayPoints.count) / speed)
        wayPoints.append(waypoint)
    }
    
    // find all way points
    private func iterateForWaypoints(node: SCNNode) {
        if let name = node.name, name.hasPrefix(waypointPrefix) {
            let waypoint = Waypoint(pos: node.simdWorldPosition,
                                    tangent: SIMD3<Float>(repeating: 0),
                                    rot: node.simdWorldOrientation,
                                    time: Double(wayPoints.count) / speed)
            wayPoints.append(waypoint)
        }
        
        for child in node.childNodes {
            if let name = child.name, !name.hasPrefix("_system") {
                // ignore child nodes part of another system
                iterateForWaypoints(node: child)
            }
        }
    }
    
    // generate a spline if given 2 positions and 2 tangents
    private func hermiteCurve(pos1: Float, pos2: Float, tangent1: Float, tangent2: Float, time: Float) -> Float {
        let tSqr = time * time
        let tCube = tSqr * time
        let h1 = 2.0 * tCube - 3.0 * tSqr + 1.0
        let h2 = -2.0 * tCube + 3.0 * tSqr
        let h3 = tCube - 2.0 * tSqr + time
        let h4 = tCube - tSqr
        let spline = h1 * pos1 + h2 * pos2 + h3 * tangent1 + h4 * tangent2
        return spline
    }
    
    // generate approximate spline tangents for every point
    private func calculateTangents() {
        for i in 0..<wayPoints.count {
            let next = (i + 1) % wayPoints.count
            let prev = (i + wayPoints.count - 1) % wayPoints.count
            wayPoints[i].tangent = (wayPoints[next].pos - wayPoints[prev].pos) / 3
        }
    }
    
    // MARK: - UpdatableComponent
    func update(deltaTime seconds: TimeInterval, isServer: Bool) {
        self.update(deltaTime: seconds)
    }

    override func update(deltaTime seconds: TimeInterval) {
        currentTime += TimeInterval(seconds)
        calcCurrentFrameIndex()

        var alpha = Float((currentTime - wayPoints[currentFrame].time) / (wayPoints[currentFrame + 1].time - wayPoints[currentFrame].time))
        alpha = clamp(alpha, 0.0, 1.0)

        let curPos = wayPoints[currentFrame].pos
        let curTan = wayPoints[currentFrame].tangent
        let curRot = wayPoints[currentFrame].rot
        let nextPos = wayPoints[currentFrame + 1].pos
        let nextTan = wayPoints[currentFrame + 1].tangent
        let nextRot = wayPoints[currentFrame + 1].rot

        let newPosX = hermiteCurve(pos1: curPos.x, pos2: nextPos.x, tangent1: curTan.x, tangent2: nextTan.x, time: alpha)
        let newPosY = hermiteCurve(pos1: curPos.y, pos2: nextPos.y, tangent1: curTan.y, tangent2: nextTan.y, time: alpha)
        let newPosZ = hermiteCurve(pos1: curPos.z, pos2: nextPos.z, tangent1: curTan.z, tangent2: nextTan.z, time: alpha)
        let newQuat = simd_slerp(curRot, nextRot, alpha)
        node.simdWorldPosition = SIMD3<Float>(newPosX, newPosY, newPosZ)
        node.simdWorldOrientation = newQuat

        // update child rigid bodies to percolate into physics
        guard let entity = entity as? GameObject else { return }
        if let physicsNode = entity.physicsNode, let physicsBody = physicsNode.physicsBody {
            physicsBody.resetTransform()
        }
    }
}
