/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages interactions for the slingshot.
*/

import SceneKit
import simd
import AVFoundation
import os.log

extension UIColor {
    convenience init(hexRed: UInt8, green: UInt8, blue: UInt8) {
        let fred = CGFloat(hexRed) / CGFloat(255)
        let fgreen = CGFloat(green) / CGFloat(255)
        let fblue = CGFloat(blue) / CGFloat(255)

        self.init(red: fred, green: fgreen, blue: fblue, alpha: 1.0)
    }
}

enum Team: Int {
    case none = 0 // default
    case teamA
    case teamB
    
    var description: String {
        switch self {
        case .none: return NSLocalizedString("none", comment: "Team name")
        case .teamA: return NSLocalizedString("Blue", comment: "Team name")
        case .teamB: return NSLocalizedString("Yellow", comment: "Team name")
        }
    }

    var color: UIColor {
        switch self {
        case .none: return .white
        case .teamA: return UIColor(hexRed: 45, green: 128, blue: 208) // srgb
        case .teamB: return UIColor(hexRed: 239, green: 153, blue: 55)
        }
    }
}

extension Team: BitStreamCodable {
    // We do not use the stanard enum encoding here to implement a tiny
    // optimization; 99% of blocks are on no team, so this saves us almost 1 bit per block.
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .none:
            bitStream.appendBool(false)
        case .teamA:
            bitStream.appendBool(true)
            bitStream.appendBool(true)
        case .teamB:
            bitStream.appendBool(true)
            bitStream.appendBool(false)
        }
    }

    init(from bitStream: inout ReadableBitStream) throws {
        let hasTeam = try bitStream.readBool()
        if hasTeam {
            let isTeamA = try bitStream.readBool()
            self = isTeamA ? .teamA : .teamB
        } else {
            self = .none
        }
    }
}

public func clamp<T>(_ value: T, _ minValue: T, _ maxValue: T) -> T where T: Comparable {
    return min(max(value, minValue), maxValue)
}

protocol CatapultDelegate: class {
    func catapultDidBeginGrab(_ catapult: Catapult)
    func catapultDidMove(_ catapult: Catapult, stretchDistance: Float, stretchRate: Float)
    func catapultDidLaunch(_ catapult: Catapult, velocity: GameVelocity)
    func catapultDidBreak(_ catapult: Catapult, justKnockedout: Bool, vortex: Bool)
}

struct CatapultProps {
    // angle of rotation around base from 0
    var minYaw = -45.0
    var maxYaw = 45.0
    
    // angle of rotation up/down to angle shots
    var minPitch = -30.0
    var maxPitch = 30.0
    
    // when launched, the pull distance is normalized and scaled to this (linear not exponential power)
    var minVelocity = 1.0 // so the ball doesn't just drop and take out your own stuff
    var maxVelocity = 50.0
    
    // when pulled, these are the min/max stretch of pull
    var minStretch = 0.05 // always have some energy, so ball doesn't just drop
    var maxStretch = 5.0 // ball will poke through sling if bigger
   
    // these animations play with these times
    var growAnimationTime = 0.2
    var dropAnimationTime = 0.3
    var grabAnimationTime = 0.15 // don't set to 0.2, ball/sling separate
    
    // before another ball appears, there is a cooldown and the grow/drop animation
    var cooldownTime = 3.0
    
    // how close payer has to be from the pull to grab it
    var pickRadius = 5.0
}

// Catapult provides an interface which users can use to manipulate the sling
//  CatapultInteraction which represents player's interaction with the catapult use these interfaces to manipulate catapult locally
//  Network sync is handled by CatapultInteraction
class Catapult: GameObject, Grabbable {
    // This is the catapult model - base + fork.
    let base: SCNNode
    
    // Projectiles are fired out of the local -Z axis direction. (worldFront)
    // This is the upper center of the base where projectiles are fired through.
    private let pullOrigin: SCNNode
    
    private let catapultStrap: SCNNode
    
    // Can drop the ball from the active to below with a transaction.
    // Below rests on the strap, and above is above that at the top of the fork.
    // This must be finish before the catapult can be grabbed, or the transition
    // animations will compete.
    private let ballOriginInactiveAbove: SCNNode
    private let ballOriginInactiveBelow: SCNNode
    
    ///////////////////////////
    // This is a rope simulator only for the new catapult.
    let rope: CatapultRope

    // original world position of sling to restore the position to
    private var baseWorldPosition = SIMD3<Float>()
    
    // Player who grabbed a catapult. A player can only operate one catapult at a time.
    // Players/teams may be restricted to a set of catapults.
    // Note: Player setting is managed by CatapultInteraction which will resolves sync.
    //       Player do not get set in clients, since clients do not need to know who grabbed the catapult,
    //       whereas server needs to know the player owning the catapult to avoid conflicts.
    var player: Player?
    var isGrabbed: Bool = false { // In the case of clients, actual player owner does not need to be known
        didSet {
            if !isGrabbed {
                player = nil
            }
        }
    }
    private var ballCanBeGrabbed = false
    private(set) var isPulledTooFar = false
    
    // Last cameraInfo used to computed premature release (such as when other ball hit the catapult)
    private(set) var lastCameraInfo = CameraInfo(transform: .identity)

    // highlight assistance
    var isVisible: Bool = false
    var isHighlighted: Bool = false
    var projectedPos = SIMD3<Float>(repeating: 0.0)
    var highlightColor = UIColor.white
    var highlightObject: SCNNode?
    
    // for audio:
    let audioEnvironment: AVAudioEnvironmentNode
    let audioPlayer: CatapultAudioSampler
    
    // The starting position of the player when they grab the pull
    private var playerWorldPosition = SIMD3<Float>(repeating: 0.0)
    
    private(set) var disabled = false
    
    // Each catapult has a unique index.
    // 1-3 are on one side, 4-6 are on the other side
    private(set) var catapultID: Int = 0
    private(set) var team: Team = .none
    private(set) var teamName: String
    
    // Grabbable ID to be set by GrabInteraction
    var grabbableID = 0
    
    // Can only pull back the slingshot for now.  Eventually will be able to direct shots within a cone.
    private var stretch: Double = 0
    private var lastStretch: Double = 0
    private var lastStretchTime: TimeInterval = 0

    // Track the start of the grab.  Can use for time exceeded auto-launch.
    private var firstGrabTime: Double = 0
    // Stores the last launch of a projectile.  Cooldown while sling animates and bounces back.
    private var lastLaunchTime: Double = 0
    
    // This a placeholder that we make visible/invisible for the pull that represents the projectile to launch.
    // That way it can be tested against the stretch of the sling.
    private(set) var projectile: SCNNode?
    private(set) var projectileType = ProjectileType.none
    private var projectileScale: SIMD3<Float> = SIMD3<Float>(repeating: 1.0)
    
    private var props = CatapultProps()
    var coolDownTime: TimeInterval { return props.cooldownTime }
    
    weak var delegate: CatapultDelegate?
        
    // convenience for idenfifying catapult during collisions
    static let CollisionKey = "id"

    enum StrapVisible {
        case hidden
        case visible
    }
    
    private var strapVisible: StrapVisible = .hidden {
        didSet {
            updateStrapVisibility()
        }
    }
    
    private func updateStrapVisibility() {
        switch strapVisible {
        case .hidden:
            catapultStrap.isHidden = true
        case .visible:
            catapultStrap.isHidden = false
        }
    }
    
    enum BallVisible {
        case hidden
        case partial
        case visible
    }
    
    // Whether the ball in the sling is visible or partially visible.
    var ballVisible: BallVisible = .hidden {
        didSet {
            updateFakeProjectileVisibility()
        }
    }
    
    private func updateFakeProjectileVisibility() {
        switch ballVisible {
            case .hidden:
                projectile?.opacity = 1.0
                projectile?.isHidden = true
                projectile?.simdWorldPosition = ballOriginInactiveAbove.simdWorldPosition
                projectile?.simdScale = SIMD3<Float>(repeating: 0.01)
            
            case .partial:
                projectile?.opacity = 1.0
                projectile?.isHidden = false
                animateBallGrowAndDrop()
            
            case .visible:
                projectile?.opacity = 1.0
                projectile?.isHidden = false
                // it's in the strap fromn .partial animation
        }
    }
    
    public func animationRopeToRestPose(duration: TimeInterval) {
        rope.interpolateToRestPoseAnimation(duration)
    }
    
    public func animateBallGrowAndDrop() {
        // the block is the total time of the transcation, so sub-blocks are limited by that too
        SCNTransaction.animate(duration: props.growAnimationTime, animations: {
        
            // correct the rope sim by animating back to reset pose no matter what
            let fixupLaunchAnimationTime = 0.1
            rope.interpolateToRestPoseAnimation(fixupLaunchAnimationTime)
            
            // first scale the ball from small to original size
            projectile?.simdScale = projectileScale
            
        }, completion: {
            // after back to scale, then run the ball drop
            SCNTransaction.animate(duration: self.props.dropAnimationTime, animations: {
                // next drop from ballOriginInactiveAbove to ballOriginInactive
                self.projectile?.simdWorldPosition = self.ballOriginInactiveBelow.simdWorldPosition
            }, completion: {
                // only allow the ball to be grabbed after animation completes
                self.ballCanBeGrabbed = true
            })
        })
    }
    
    //  distance away from catapult base
    public func distanceFrom(_ worldPos: SIMD3<Float>) -> Float {
        let distance = worldPos - base.simdWorldPosition
        return length(distance)
    }
    
    public static func replaceCatapultPlaceholder(_ placeholder: SCNNode) -> SCNNode {
        let node = SCNNode.loadSCNAsset(modelFileName: "catapult")
        
        // somehow setting the world transform doesn't update the Euler angles (180, 0, 180) is decoded
        //  but need it to be 0, 180, 0
        node.transform = placeholder.transform
        node.simdEulerAngles = placeholder.simdEulerAngles
        
        // Add physics body to it
        node.simdWorldPosition += SIMD3<Float>(0.0, 0.2, 0.0)
        node.physicsBody?.resetTransform()
        
        guard let baseGeomNode = node.childNode(withName: "catapultBase", recursively: true) else { fatalError("No catapultBase") }
        guard let prongGeomNode = node.childNode(withName: "catapultProngs", recursively: true) else { fatalError("No catapultProngs") }
        
        // shift center of mass of the prong from the bottom
        // the 0.55 value is from experimentation
        let prongPivotShiftUp = SIMD3<Float>(0.0, 0.55, 0.0)
        prongGeomNode.simdPivot = float4x4(translation: prongPivotShiftUp)
        prongGeomNode.simdPosition += prongPivotShiftUp
        
        let baseShape = SCNPhysicsShape(node: baseGeomNode, options: [.type: SCNPhysicsShape.ShapeType.convexHull])
        let prongShape = SCNPhysicsShape(node: prongGeomNode, options: [.type: SCNPhysicsShape.ShapeType.convexHull])
        let identityMatrix = SCNMatrix4Identity as NSValue
        let compoundShape = SCNPhysicsShape(shapes: [baseShape, prongShape], transforms: [identityMatrix, identityMatrix])
        node.physicsBody?.physicsShape = compoundShape

        // rename back to placeholder name must happen after gameObject is assigned
        // currently placeholders are all Catapult1 to Catapult6, they may be under a teamA, teamB parent
        // so stash the placeholder name for later
        if let oldName = placeholder.name {
            node.setValue(oldName, forKey: "nameRestore")
        }
        
        placeholder.parent!.replaceChildNode(placeholder, with: node)
        
        node.name = "catapult"
        os_log(.info, "Catapult placeholder node %s replaced with %s", placeholder.name!, node.name!)
        
        return node
    }
    
    init(_ node: SCNNode, sfxCoordinator: SFXCoordinator, identifier: Int, gamedefs: [String: Any]) {
        self.base = node
        self.audioEnvironment = sfxCoordinator.audioEnvironment
        
        // Base team and name off looking up teamA or teamB folder in the level parents
        // This won't work on the old levels.
        self.team = base.team
        self.teamName = base.team.description
    
        // have team id established
        base.setPaintColors()
        
        // correct for the pivot point to place catapult flat on ground
        base.position.y -= 0.13
        
        // highlight setup
        highlightObject = node.childNode(withName: "Highlight", recursively: true)
        if highlightObject != nil {
            highlightObject = highlightObject?.findNodeWithGeometry()
        }

        // hide the highlights on load
        highlightObject?.isHidden = true

        if let highlight = highlightObject,
            let geometry = highlight.geometry,
            let material = geometry.firstMaterial,
            let color = material.diffuse.contents as? UIColor {
            highlightColor = color
        }
        // they should only have y orientation, nothing in x or z
        // current scene files have the catapults with correct orientation, but the
        // eulerAngles are different - x and z are both π, y is within epsilon of 0
        // That's from bad decomposition of the matrix.  Need to restore the eulerAngles from the source.
        // Especially if we have animations tied to the euler angles.
        if abs(node.eulerAngles.x) > 0.001 || abs(node.eulerAngles.z) > 0.001 {
            os_log(.error, "Catapult can only have y rotation applied")
        }
    
        // where to place the ball so it sits on the strap
        guard let catapultStrap = base.childNode(withName: "catapultStrap", recursively: true) else {
            fatalError("No node with name catapultStrap")
        }
        self.catapultStrap = catapultStrap
        
        // this only rotates, and represents the center of the catapult through which to fire
        guard let pullOrigin = base.childNode(withName: "pullOrigin", recursively: true) else {
            fatalError("No node with name pullOrigin")
        }
        self.pullOrigin = pullOrigin
        
        // This is a rope simulation meant for a fixed catapult, the catapult rotates.
        rope = CatapultRope(node)
        
        // attach ball to the inactive strap, search for ballOriginInactiveBelow
        guard let ballOriginInactiveBelow = base.childNode(withName: "ballOriginInactiveBelow", recursively: true) else {
            fatalError("No node with name ballOriginInactiveBelow")
        }
        guard let ballOriginInactiveAbove = base.childNode(withName: "ballOriginInactiveAbove", recursively: true) else {
            fatalError("No node with name ballOriginInactiveAbove")
        }
        self.ballOriginInactiveBelow = ballOriginInactiveBelow
        self.ballOriginInactiveAbove = ballOriginInactiveAbove
        
        // ball will be made visible and drop once projectile is set and cooldown exceeded
        strapVisible = .visible
        
        self.catapultID = identifier
        
        base.setValue(catapultID, forKey: Catapult.CollisionKey)
        
        audioPlayer = CatapultAudioSampler(node: base, sfxCoordinator: sfxCoordinator)
        
        super.init(node: node, index: nil, gamedefs: gamedefs, alive: true, server: false)
        
        // use the team to set the collision category mask
        if let physicsNode = physicsNode, let physBody = physicsNode.physicsBody {
            if team == .teamA {
                physBody.categoryBitMask = CollisionMask.catapultTeamA.rawValue
                physBody.collisionBitMask |= CollisionMask.catapultTeamB.rawValue
            } else if team == .teamB {
                physBody.categoryBitMask = CollisionMask.catapultTeamB.rawValue
                physBody.collisionBitMask |= CollisionMask.catapultTeamA.rawValue
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProjectileType(projectileType: ProjectileType, projectile: SCNNode) {
        self.projectile?.removeFromParentNode()
        self.projectile = projectile
        self.projectileType = projectileType
        projectileScale = projectile.simdScale
        
        // the rope adjusts to the radius of the ball
        let projectilePaddingScale: Float = 1.0
        rope.setBallRadius(projectile.boundingSphere.radius * projectilePaddingScale)
        
        // need ball to set a team, and then can color with same mechanism
        //projectile.setPaintColor()
        
        // will be made visible and drop when cooldown is exceeded,
        // this way ball doesn't change suddenly while visible
        ballVisible = .hidden
        updateFakeProjectileVisibility()
    }
    
    func updateProps() {
        
        let obj = self

        props.minStretch = obj.propDouble("minStretch")!
        props.maxStretch = obj.propDouble("maxStretch")!

        props.minYaw = obj.propDouble("minYaw")!
        props.maxYaw = obj.propDouble("maxYaw")!

        props.minPitch = obj.propDouble("minPitch")!
        props.maxPitch = obj.propDouble("maxPitch")!

        props.minVelocity = obj.propDouble("minVelocity")!
        props.maxVelocity = obj.propDouble("maxVelocity")!

        props.cooldownTime = obj.propDouble("cooldownTime")!
        props.pickRadius = obj.propDouble("pickRadius")!
    }
    
    // MARK: - Catapult Grab
    
    func canGrab(cameraRay: Ray) -> Bool {
        if isGrabbed {
            return false
        }
        if disabled {
            return false
        }
        // there is a cooldown timer before you can launch again
        // when animation completes this will be set to true
        if !ballCanBeGrabbed {
            return false
        }
        if !isCatapultStable {
            return false
        }
        if !hitTestPull(cameraRay: cameraRay) {
            return false
        }
        return true
    }

    private func hitTestPull(cameraRay: Ray) -> Bool {
        // Careful not to make this too large or you'll pick a neighboring slingshot or one across the table.
        // We're not sorting hits across all of the slignshots and picking the smallest, but we visit them all.
        // Within radius behind the ball/pull allow the slingshot to be picked.
        let playerDistanceFromPull = cameraRay.position - pullOrigin.simdWorldPosition
        
        // This is a linear distance along the current firing direction of the catapult
        // Just using it here to make sure you're behind the pull (the pull is visible).
        let stretchDistance = dot(playerDistanceFromPull, -firingDirection())

        // make sure player is on positive side of pull + some fudge factor to make sure we can see it
        // to avoid flickering highlight on and off, we add a buffer when highlighted
        if stretchDistance <= 0.01, let highlight = highlightObject, highlight.isHidden {
            return false
        } else if stretchDistance < -0.03 { // slack during highlight mode
            return false
        }
        
        // player can be inside a highlight radius or the pick radius
        // one approach is to auto grab when within radius (but facing the catapult)
        if length(playerDistanceFromPull) > Float(props.pickRadius) {
            return false
        }
        
        return true
    }
    
    private var isCatapultStable = true // Stable means not knocked and not moving
    private var isCatapultKnocked = false // Knocked means it is either tilted or fell off the table
    private var lastPosition: SIMD3<Float>?
    
    private var catapultKnockedStartTime = TimeInterval(0.0)
    var catapultKnockedTime: TimeInterval { return !isCatapultKnocked ? 0.0 : GameTime.time - catapultKnockedStartTime }
    
    private let catapultPhysicsSettleTime = 5.0
    private let minStableTiltBaseUpY: Float = 0.7
    private let maxSpeedToCountAsStable: Float = 0.05
    
    func updateCatapultStable() {
        guard !disabled else { return }
        
        // Catapult will be unstable when the physics settles, therefore we do not update catapult's stability status
        guard GameTime.timeSinceLevelStart > catapultPhysicsSettleTime else { return }
        
        // Cannot use simdVelocity on client since simdVelocity could be high from physicsSync interacting with local physics engine
        guard let lastPositionNonNil = lastPosition else {
            lastPosition = base.presentation.simdWorldPosition
            return
        }
        let position = base.presentation.simdWorldPosition
        let speed = length((position - lastPositionNonNil) / Float(GameTime.deltaTime))
        lastPosition = position
        
        // Base below table?
        // Base tilted? base's up vector must maintain some amount of y to be determined as stable
        let baseUp = normalize(base.presentation.simdTransform.columns.1)
        if position.y < -1.0 || abs(baseUp.y) < minStableTiltBaseUpY {
            // Switch to knocked mode
            if !isCatapultKnocked {
                catapultKnockedStartTime = GameTime.time
            }
            
            isCatapultKnocked = true
            isCatapultStable = false
            return
        }
        
        isCatapultKnocked = false
        
        // Base could be moving although the catapult is not knocked
        isCatapultStable = speed < maxSpeedToCountAsStable
    }
    
    // When a user has control of a slingshot, no other player can grab it.
    func serverGrab(cameraRay: Ray) {
        guard !isGrabbed else { os_log(.error, "Trying to grab catapult with player"); return }
        os_log(.debug, "(Server) Catapult%d grabbed by player", catapultID)

        // do slingshot grab
        if let slingComponent = base.gameObject?.component(ofType: SlingshotComponent.self) {
            slingComponent.setGrabMode(state: true)
        }
    }
    
    func onGrabStart() {
        os_log(.debug, "(Player) Catapult%d grabbed by player", catapultID)
        
        // do local effects/haptics if this event was generated by the current player
        delegate?.catapultDidBeginGrab(self)
    }

    func onGrab(_ cameraInfo: CameraInfo) {
        // this is now always at the center, so it shouldn't be affected by yaw
        baseWorldPosition = base.presentation.simdWorldPosition
        
        firstGrabTime = GameTime.time
        
        playerWorldPosition = cameraInfo.ray.position
       
        let ballPosition = computeBallPosition(cameraInfo)
        
        rope.grabBall(ballPosition)
            
        strapVisible = .visible
        ballVisible = .visible
        
        alignCatapult(cameraInfo: cameraInfo) // rotate the slingshot before we move it
        animateGrab(ballPosition)
    
        isPulledTooFar = false
    }
    
    func animateGrab(_ ballPosition: SIMD3<Float>) {
        // here we want to animate the rotation of the current yaw to the new yaw
        // and also animate the strap moving to the center of the view
        
        // drop from ballOriginInactiveAbove to ballOriginInactive in a transaction
        SCNTransaction.animate(duration: props.grabAnimationTime, animations: {
            // animate the sling and ball to the camera
            rope.updateRopeModel()
            
            // animate the ball to the player
            projectile?.simdWorldPosition = ballPosition
        })
    }
    
    func doHighlight(show: Bool, sfxCoordinator: SFXCoordinator?) {
        guard let highlightNode = highlightObject else { return }

        isHighlighted = show
        highlightNode.isHidden = !show
            
        if show {
            let intensity = CGFloat(sin((Date().timeIntervalSince1970).truncatingRemainder(dividingBy: 1) * 3.1415 * 2.0) * 0.2)
            if let geometry = highlightNode.geometry, let material = geometry.firstMaterial {
                let color = CIColor(color: highlightColor)
                material.diffuse.contents = UIColor(red: clamp(color.red + intensity, 0, 1),
                                                    green: clamp(color.green + intensity, 0, 1),
                                                    blue: clamp(color.blue + intensity, 0, 1),
                                                    alpha: 1.0)
            }
        }

        sfxCoordinator?.catapultDidChangeHighlight(self, highlighted: show)
    }
    
    private func firingDirection() -> SIMD3<Float> {
        // this can change as the catapult rotates
        return base.simdWorldFront
    }
    
    // world distance from the pull to the player
    private func stretchDistance(cameraRay: Ray) -> Float {
        let stretchDelta = cameraRay.position - pullOrigin.simdWorldPosition
        let stretchDistance = dot(stretchDelta, -firingDirection())
        return stretchDistance
    }
    
    // MARK: - Sling Move
    
    func computeBallPosition(_ cameraInfo: CameraInfo) -> SIMD3<Float> {
        let cameraRay = cameraInfo.ray
        
        // These should be based on the projectile radius.
        // This affects centering of ball, and can hit near plane of camera
        // This is always centering to one edge of screen independent of screen orient
        // We always want the ball at the bottom of the screen.
        let distancePullToCamera: Float = 0.21
        let ballShiftDown: Float = 0.2
    
        var targetBallPosition = cameraRay.position + cameraRay.direction * distancePullToCamera
    
        let cameraDown = -normalize(cameraInfo.transform.columns.1).xyz
        targetBallPosition += cameraDown * ballShiftDown
    
        // Clamp to only the valid side
        let pullWorldPosition = pullOrigin.simdWorldPosition
        if pullWorldPosition.z < 0.0 {
            targetBallPosition.z = min(targetBallPosition.z, pullWorldPosition.z)
        } else {
            targetBallPosition.z = max(targetBallPosition.z, pullWorldPosition.z)
        }
    
        // Clamp to cone/circular core
        let yDistanceFromPull = max(0.0, pullWorldPosition.y - targetBallPosition.y)
        let minBallDistanceFromPull: Float = 0.5
        let pullBlockConeSlope: Float = 1.0
        let pullBlockConeRadius = yDistanceFromPull / pullBlockConeSlope
        let pullBlockCoreRadius = max(minBallDistanceFromPull, pullBlockConeRadius)
    
        // if pull is in the core, move it out.
        let pullWorldPositionGrounded = SIMD3<Float>(pullWorldPosition.x, 0.0, pullWorldPosition.z)
        let targetPullPositionGrounded = SIMD3<Float>(targetBallPosition.x, 0.0, targetBallPosition.z)
        let targetInitialToTargetPull = targetPullPositionGrounded - pullWorldPositionGrounded
    
        if pullBlockCoreRadius > length(targetInitialToTargetPull) {
        let moveOutDirection = normalize(targetInitialToTargetPull)
        let newTargetPullPositionGrounded = pullWorldPositionGrounded + moveOutDirection * pullBlockCoreRadius
        targetBallPosition = SIMD3<Float>(newTargetPullPositionGrounded.x, targetBallPosition.y, newTargetPullPositionGrounded.z)
        }
        
        // only use the 2d distance, so that user can gauage stretch indepdent of mtch
        var distance2D = targetBallPosition - pullWorldPosition
        let stretchY = abs(distance2D.y)
        distance2D.y = 0
        
        var stretchDistance = length(distance2D)
        stretch = clamp(Double(stretchDistance), props.minStretch, props.maxStretch)
        
        // clamp a little bit farther than maxStretch
        // can't let the strap move back too far right now
        let clampedStretchDistance = Float(1.1 * props.maxStretch)
        if stretchDistance > clampedStretchDistance {
            targetBallPosition = (clampedStretchDistance / stretchDistance) * (targetBallPosition - pullWorldPosition) + pullWorldPosition
            stretchDistance = clampedStretchDistance
        }
        
        // Make this optional, not required.  You're often at max stretch.
        // Also have a timer for auto-launch.  This makes it very difficuilt to test
        // storing state in member data
        isPulledTooFar = stretchDistance > Float(props.maxStretch) || stretchY > Float(props.maxStretch)
        
        return targetBallPosition
    }
    
    func alignCatapult(cameraInfo: CameraInfo) {
        let targetBallPosition = computeBallPosition(cameraInfo)
        
        // Set catapult position
        var catapultFront = pullOrigin.simdWorldPosition - targetBallPosition
        catapultFront.y = 0.0
        base.simdWorldPosition = baseWorldPosition
        base.simdLook(at: baseWorldPosition + catapultFront)

        if let physicsBody = base.physicsBody {
            physicsBody.isAffectedByGravity = false
            physicsBody.resetTransform()
        }
    }
    
    // As players move, track the stretch of the sling.
    func move(cameraInfo: CameraInfo) {
        // move actions can be processed only after the catapult has been released
        guard isGrabbed else { os_log(.error, "trying to move before grabbing catapult"); return }
        
        lastCameraInfo = cameraInfo
        let targetBallPosition = computeBallPosition(cameraInfo)
        
        // Set catapult position
        var catapultFront = pullOrigin.simdWorldPosition - targetBallPosition
        catapultFront.y = 0.0
        base.simdWorldPosition = baseWorldPosition
        base.simdLook(at: baseWorldPosition + catapultFront)
        
        base.physicsBody?.isAffectedByGravity = false
        base.physicsBody?.resetTransform()
        
        guard let projectile = projectile else { fatalError("Grabbed but no projectile") }
        projectile.simdWorldPosition = targetBallPosition
        
        rope.moveBall(targetBallPosition)
        
        // calculate the change in stretch position and rate for audio:
        var stretchRate: Float = 0
        if GameTime.time - lastStretchTime > 0 {
            stretchRate = Float((stretch - lastStretch) / (GameTime.time - lastStretchTime))
        }
 
        delegate?.catapultDidMove(self, stretchDistance: Float(stretch), stretchRate: stretchRate)

        lastStretch = stretch
        lastStretchTime = GameTime.time
    }
    
    // MARK: - Catapult Launch
    
    func onLaunch(velocity: GameVelocity) {
        guard isGrabbed else { return }
        
        // can't grab again until the cooldown animations play
        ballCanBeGrabbed = false
        
        // update local information for current player if that is what is pulling the catapult
        os_log(.debug, "Catapult%d launched", catapultID)

        // start the launch animation
        rope.launchBall()
        
        // must reset the move to distance 0 before the launch, otherwise it will start a new
        // stretch sound.
        delegate?.catapultDidMove(self, stretchDistance: 0.0, stretchRate: 0)
        delegate?.catapultDidLaunch(self, velocity: velocity)

        // set the ball to invisible
        ballVisible = .hidden
        
        // record the last launch time, and enforce a cooldown before ball reappears (need an update call then?)
        lastLaunchTime = GameTime.time
    }
    
    func tryGetLaunchVelocity(cameraInfo: CameraInfo) -> GameVelocity? {
        guard let projectile = projectile else {
            fatalError("Trying to launch without a ball")
        }
        
        // Move the catapult to make sure that it is moved at least once before launch (prevent NaN in launch direction)
        move(cameraInfo: cameraInfo)
        
        let stretchNormalized = clamp((stretch - props.minStretch) / (props.maxStretch - props.minStretch), 0.0, 1.0)
        
        // this is a lerp
        let velocity = props.minVelocity * (1.0 - stretchNormalized) +
                       props.maxVelocity * stretchNormalized
        
        let launchDir = normalize(pullOrigin.simdWorldPosition - projectile.simdWorldPosition)
        let liftFactor = Float(0.05) * abs(1.0 - dot(launchDir, SIMD3<Float>(0.0, 1.0, 0.0))) // used to keep ball in air longer
        let lift = SIMD3<Float>(0.0, 1.0, 0.0) * Float(velocity) * liftFactor
        guard !launchDir.hasNaN else { return nil }
        
        let velocityVector = GameVelocity(origin: projectile.simdWorldPosition, vector: launchDir * Float(velocity) + lift)

        return velocityVector
    }
    
    func releaseSlingGrab() {
        // restore the pull back to resting state
        // do this by calling slingshot release
        if let slingComponent = base.gameObject?.component(ofType: SlingshotComponent.self) {
            slingComponent.setGrabMode(state: false)
        }
        
        base.physicsBody?.isAffectedByGravity = true
    }
    
    // MARK: - Hit By Object
    
    func processKnockOut(knockoutInfo: HitCatapult) {
        // hide the ball and strap
        strapVisible = .hidden
        ballVisible = .hidden
        disabled = true
        
        // Remove everything except catpault base/prong
        delegate?.catapultDidBreak(self, justKnockedout: knockoutInfo.justKnockedout, vortex: knockoutInfo.vortex)
    }
    
    // MARK: - Auxiliary
    
    func update() {
        if disabled {
            ballVisible = .hidden
            return
        }
        
        rope.updateRopeModel()
        
        // ball on the sling will remain invisible until cooldown time exceeded
        // base this on animation of sling coming back to rest
       if ballVisible == .hidden {
            // make sure cooldown doesn't occur starting the ball animation
            // until a few seconds after loading the level
            if lastLaunchTime == 0 {
                lastLaunchTime = GameTime.time
            }
        
            // only allow grabbing the ball after the cooldown animations play (grow + drop)
            let timeElapsed = GameTime.time - lastLaunchTime
            var timeForCooldown = props.cooldownTime - props.growAnimationTime - props.dropAnimationTime
            if timeForCooldown < 0.01 {
                os_log(.error, "cooldown time needs to be long enough to play animations")
                timeForCooldown = 0.0
            }
            let startCooldownAnimation = timeElapsed > timeForCooldown
            if startCooldownAnimation {
                // show the ball at the ballOrigin, that's in the sling
                ballVisible = .partial
            }
        }
        
        updateCatapultStable()
        
        // Make sure that the ball stays in its place even if the catapult move
        if ballCanBeGrabbed {
            if isGrabbed {
                guard let projectile = projectile else { fatalError("isGrabbed but has no projectile") }
                rope.moveBall(projectile.simdWorldPosition)
            } else {
                projectile?.simdWorldPosition = ballOriginInactiveBelow.presentation.simdWorldPosition
            }
        }
    }

    override func apply(physicsData nodeData: PhysicsNodeData, isHalfway: Bool) {
        // for catapults, we only apply physics updates when we're not grabbed.
        guard !isGrabbed else { return }
        super.apply(physicsData: nodeData, isHalfway: isHalfway)
    }
}
