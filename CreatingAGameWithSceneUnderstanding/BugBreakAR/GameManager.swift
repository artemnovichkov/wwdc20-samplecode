/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Game Manager
*/

import ARKit
import RealityKit

class GameManager {
    enum GameState {
        case applicationLaunched
        case waitingForAssetsLoaded
        case waitForEnoughClassification
        case freeplay
    }

    // Dependencies
    weak var viewController: GameViewController?
    var inputSystemInstance: InputSystem?
    var voxels: Voxels?
    weak var assets: GameAssets?

    // Game state related
    var currentState = GameState.applicationLaunched
    var assetsLoaded = false

    // Creature spawning
    var creaturePool: CreaturePool?
    var spawnController: Spawn!
    var lookingForSpawnPoint = false
    var creaturesAnchor = AnchorEntity()
    var creatureEntities = [CreatureEntity]()
    var radarMap: RadarMap!
    var voxelTouchTrail: VoxelCursor?
    var creatureInTractorBeam = false

    // Sound
    var audioAnchor: AnchorEntity?
    var popSFX: AudioFileResource?

    private let tapPromptFirstAppearTime: Float = 0.0
    private let tapPromptAppearTime: Float = 6.0
    private var tapPromptAppearTimer: Float = 0.0
    private var messageFadeDuration: TimeInterval = 0.33
    private var tapPromptIsShowing = false

    private let radarIntroWatchDogTimer: TimeInterval = 10.0

    /// Initializes class instance
    init(viewController: GameViewController, assets: GameAssets) {
        self.viewController = viewController
        self.assets = assets
        // The voxels require the asset loader to have been set up first
        self.voxels = Voxels(gameManager: self)
        guard let voxelsInstance = voxels else { return }
        self.voxelTouchTrail = VoxelCursor(voxels: voxelsInstance)
        // The creature entities require the voxels to have been set up first

        creaturePool = CreaturePool(gameManager: self)
        spawnController = Spawn(gameManager: self)
        // Instantiate our input system
        let inputSystem = InputSystem(target: viewController, action: nil)
        inputSystem.setupDependencies(arView: viewController.arView)
        inputSystem.inputSystemDelegate = self
        inputSystem.delegate = viewController
        inputSystemInstance = inputSystem

        // Set the delegate so we can reject certain touches as input for our
        // custom Gesture Recognizer
        viewController.delegate = self
        viewController.tapToPlaceCreatureLabel.alpha = 0.0
        // Listen for touches using our custom gesture recognizer
        viewController.arView.addGestureRecognizer(inputSystem)
        // Root anchor that all creatures live under
        viewController.arView.scene.addAnchor(creaturesAnchor)
        // Set up the radar map
        radarMap = RadarMap(frame: Constants.radar2DLocation, from: viewController.arView.bounds)
        // Proceed to next state
        gotoState(.waitingForAssetsLoaded)
        if Options.showRadarIntro.value == false {
            radarMap.setToMinimap()
        } else {
            Timer.scheduledTimer(withTimeInterval: radarIntroWatchDogTimer,
                                 repeats: false,
                                 block: { [weak self] timer in
                timer.invalidate()
                guard let self = self else { return }
                if self.radarMap.isFullScreen {
                    self.playIntro()
                }
            })
        }
    }

    // Need to clamp delta time so that when we BP
    // we don't get systems thinking lots of time has passed
    private func clampDeltaTime(_ deltaTime: TimeInterval) -> Float {
        let clamped = deltaTime < 0.25 ? deltaTime : 1.0 / 30.0
        return Float(clamped)
    }

    // Update loop runs once per frame
    func updateLoop(deltaTimeInterval: TimeInterval) {
        let clampedDeltaTime = clampDeltaTime(deltaTimeInterval.magnitude)
        switch currentState {
        case .waitingForAssetsLoaded:
            if assetsLoaded {
                gotoState(.waitForEnoughClassification)
            }
        case .waitForEnoughClassification:
            updateRadar()
            if (Options.showRadarIntro.value && !radarMap.isFullScreen)
                || (!Options.showRadarIntro.value
                        && Classifications.numClassifications
                        >= Options.startClassificationThreshold.value) {
                gotoState(.freeplay)
            }
        case .freeplay:
            inputSystemInstance?.updateLoop()
            updateCreatures(clampedDeltaTime)
            updateRadar()
            if !Options.enableTapToPlace.value, canAddNest() {
                spawnCreature()
            }
            checkForCreatures(clampedDeltaTime)
        default:
            break
        }
    }

    func updateCreatures(_ deltaTime: Float) {
        creatureEntities.forEach { $0.updateLoop(deltaTime) }
    }

    func updateRadar() {
        if radarMap.isFullScreen {
            if Options.showRadarIntro.value {
                if  Classifications.numClassifications > Options.radarTransitionThreshold.value {
                    playIntro()
                }
            }
        } else {
            var creatureMatrices: [float4x4] = [float4x4]()
            creatureEntities.forEach { creatureMatrices.append($0.transform.matrix) }
            radarMap.updateCreatures(creatureMatrices)
        }
        guard let frame = viewController?.arView.session.currentFrame else {
            return
        }
        radarMap.updateCamera(frame.camera)
    }

    private func playIntro() {
        radarMap.transitionToMinimap {
        }
    }

    func gotoState(_ newState: GameState) {
        currentState = newState
        switch currentState {
        case .waitForEnoughClassification:
            updateRadarViewVisuals()
        case .freeplay:
            tapPromptAppearTimer = tapPromptFirstAppearTime
        default:
            break
        }
    }
}

extension GameManager {
    public func updateRadarViewVisuals() {
        if Options.showRadar.value {
            radarMap.addView(to: viewController?.view)
        } else {
            radarMap.removeView()
        }
    }

    func updateCreaturesScale() {
        creatureEntities.forEach { $0.changeCreatureScale() }
    }

    func updateCreaturesBaseSpeed() {
        creatureEntities.forEach { $0.setCreatureBaseSpeed() }
    }

    func updatePathfindingVisuals() {
        creatureEntities.forEach { $0.onDebugPathfindingOptionsUpdated() }
        viewController?.messageLabel.text = ""
    }

    func updatePathfindingEnabled() {
        creatureEntities.forEach { $0.onPathfindingEnablerUpdated() }
    }

    func updateShaderDebug() {
        creatureEntities.forEach { $0.updateShaderDebug() }
    }

    public func onAssetsLoaded() {
        audioAnchor = AnchorEntity()
        guard let sfxAnchor = audioAnchor else { return }
        viewController?.arView.scene.addAnchor(sfxAnchor)
        guard let resources = assets?.audioResources else { return }
        popSFX = resources[Constants.popAudioName]
        assetsLoaded = true
    }

    public func canAddNest() -> Bool {
        return currentState == .freeplay &&
            creatureEntities.count < Options.maxCreatureInstances.value &&
            !lookingForSpawnPoint
    }

    public func spawnCreature() {
        if !lookingForSpawnPoint {
            guard let arView = viewController?.arView else { return }
            lookingForSpawnPoint = true
            spawnController.searchForSpawnTransform(arView)
        }
    }

    public func onSpawnPointFound(_ transform: Transform) {
        spawnCreatureAtPoint(transform)
        lookingForSpawnPoint = false
    }

    public func spawnCreatureAtPoint(_ transform: Transform) {
        if let creature = creaturePool?.initCreature(atTransform: transform) {
            creatureEntities.append(creature)
        }
    }

    public func removeCreature(_ creature: CreatureEntity) {
        guard let index = creatureEntities.firstIndex(of: creature) else { return }
        creature.returnToPool()
        creatureEntities.remove(at: index)
    }

    public func shutdownGame() {
        for index in 0..<creatureEntities.count {
            creatureEntities[index].returnToPool()
        }
        voxelTouchTrail = nil
        guard let inputSystem = inputSystemInstance else { return }
        viewController?.arView.removeGestureRecognizer(inputSystem)
        viewController?.delegate = nil
        inputSystem.inputSystemDelegate = nil
        inputSystemInstance = nil
        creatureEntities.removeAll()
        creaturePool?.removeAllCreatures()
        creaturePool = nil
        assets = nil
        voxels?.removeAllVoxels()
        voxels = nil
        radarMap.removeView()
    }

    func getNearestWhackableCreature() -> CreatureEntity? {
        var closestWhackableCreature: CreatureEntity?
        var closestCreatureDistanceSqr: Float = -1
        // Sort by distance to the player
        for index in 0..<creatureEntities.count {
            let creature = creatureEntities[index]
            if creature.interaction.isWhackable {
                // Are you close enough to the creature?
                guard let creatureDistanceSqr = creature.distanceToCameraSquared() else { continue }
                if creatureDistanceSqr <= Options.whackDistanceSqr.value &&
                    (creatureDistanceSqr < closestCreatureDistanceSqr || closestWhackableCreature == nil) {
                    // Is this the closest creature?
                    closestWhackableCreature = creature
                    closestCreatureDistanceSqr = creatureDistanceSqr
                }
            }
        }
        return closestWhackableCreature
    }

    func checkForCreatures(_ deltaTime: Float) {
        if !tapPromptIsShowing, creatureEntities.isEmpty {
            if tapPromptAppearTimer >= 0 {
                tapPromptAppearTimer -= deltaTime
            } else {
                tapPromptIsShowing = true
                tapPromptAppearTimer = tapPromptAppearTime
                // Fade in
                fadeTapPrompt(fadeIn: true, text: "Tap to place creature")
            }
        } else if tapPromptIsShowing, !creatureEntities.isEmpty {
            // Fade out
            fadeTapPrompt(fadeIn: false)
        }
    }

    func fadeTapPrompt(fadeIn: Bool, text: String? = nil) {
        guard let tapPrompt = viewController?.tapToPlaceCreatureLabel else { return }
        if fadeIn {
            tapPrompt.alpha = 0.0
            tapPrompt.text = text
            tapPrompt.fadeIn(duration: messageFadeDuration, delay: 0.0, completion: { _ in })
        } else {
            tapPrompt.alpha = 1.0
            tapPrompt.fadeOut(duration: messageFadeDuration, delay: 0.0, completion: { _ in
                self.tapPromptIsShowing = false
            })
        }
    }
}

extension GameManager: InputSystemDelegate {
    func playerBeganTouch(touchTransform: Transform) {
        if Options.enableTapToPlace.value, !creatureInTractorBeam, canAddNest() {
            spawnCreatureAtPoint(touchTransform)
        }
    }

    func playerUpdatedTouchTrail(touchTransform: Transform) {
        if Options.enableTouchTrail.value {
            voxelTouchTrail?.updatePosition(touchTransform.translation)
        }
    }

    func playerAchievedWhack() {
        guard let whooshAudio = assets?.audioResources[Constants.wooshAudioName],
        let whackableCreature = getNearestWhackableCreature() else { return }
        audioAnchor?.playAudio(whooshAudio)
        whackableCreature.whack()
    }

    func playerAchievedTractorBeam() {
        guard let tractorBeamAudio = assets?.audioResources[Constants.tractorBeamActivateAudioName] else { return }
        audioAnchor?.playAudio(tractorBeamAudio)
        creatureInTractorBeam = true
    }

    func playerEndedTouch() {
        audioAnchor?.stopAllAudio()
        creatureInTractorBeam = false
    }
}

extension GameManager: GameViewControllerDelegate {
    func onSceneUpdated(_ arView: ARView, deltaTimeInterval: TimeInterval) {
        updateLoop(deltaTimeInterval: deltaTimeInterval)
        voxels?.updateVoxelColorsFromFrameBuffer(arView: arView)
    }
}
