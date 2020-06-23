/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Game View Controller
*/

import ARKit
import Combine
import os.log
import RealityKit
import UIKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate {

    let log = OSLog(subsystem: appSubsystem, category: "GameViewController")

    public weak var assets: GameAssets?

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tapToPlaceCreatureLabel: UILabel!

    var gameManager: GameManager?
    weak var delegate: GameViewControllerDelegate?
    var trackingConfiguration: ARWorldTrackingConfiguration?
    private var sceneBounds = CGSize()
    var iblResource: EnvironmentResource?

    private var sceneObserver: Cancellable?

    override var prefersStatusBarHidden: Bool { return true }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        Classifications.reset()
        // Hook up our update loop per-frame
        sceneObserver = arView.scene.subscribe(to: SceneEvents.Update.self, { event in
            self.updateLoop(deltaTimeInterval: event.deltaTime)})

        configureView()

        sceneBounds = arView.frame.size

        // Prevent the screen from being dimmed to avoid interrupting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        messageLabel.numberOfLines = 0 // Zero means no limit
        messageLabel.text = ""

        // Start the game manager first, as InputSystem relies on it.
        gameManager = GameManager(viewController: self, assets: self.assets!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Assign delegate
        arView.session.delegate = self

        // Prevent the screen from being dimmed to avoid interrupting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController else {
            return
        }
        guard let destination = navController.viewControllers.first as? DebugSettingsViewController else {
            return
        }
        OptionsSettings.onSequeToDebugSettingsViewController(destination, delegate: self)
        destination.onDismissComplete = {
            navController.dismiss(animated: true, completion: nil)
            OptionsSettings.onDebugSettingsViewControllerDismiss()
        }
    }

    func configureView() {
        self.arView.automaticallyConfigureSession = false

        resetTracking()

        // Initialize list of Scene Understanding options
        self.arView.environment.sceneUnderstanding.options = []

        // Turn on occlusion from the scene reconstruction's mesh.
        self.arView.environment.sceneUnderstanding.options = [.collision, .physics]

        if Options.showShadows.value {
            arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        }

        // For performance, disable render options that are not required for this app.
        self.arView.renderOptions = [.disablePersonOcclusion]

        if !Options.showDepthOfField.value {
            arView.renderOptions.insert(.disableDepthOfField)
        }
        if !Options.showMotionBlur.value {
            arView.renderOptions.insert(.disableMotionBlur)
        }
        if !Options.showCameraGrain.value {
            arView.renderOptions.insert(.disableCameraGrain)
        }

        // Shows you colliders and a few other things
        if Options.showPhysicsMesh.value {
            arView.debugOptions.insert(ARView.DebugOptions.showPhysics)
        }
        if Options.showSpatialMesh.value {
            arView.debugOptions.insert(ARView.DebugOptions.showSceneUnderstanding)
        }
        if Options.activateOcclusion.value {
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }

        setupIBL()
    }

    func resetTracking(_ totalReset: Bool = false) {
        trackingConfiguration = ARWorldTrackingConfiguration()
        trackingConfiguration?.sceneReconstruction = .meshWithClassification
        trackingConfiguration?.planeDetection = [.horizontal, .vertical]
		arView.session.run(trackingConfiguration!)
        enableEnvironmentTexturing(Options.enableEnvironmentTexturing.value, force: true)
    }

    func setupIBL() {
		if iblResource == nil {
			iblResource = try? EnvironmentResource.load(named: "HDR_Environment")
		}

        enableIBL(Options.enableIBL.value, true)
        arView.environment.background = .cameraFeed(exposureCompensation: 0.0)
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }

    public func nearbyFaceWithClassification(
        to location: SIMD3<Float>,
        maxDist: Float,
        completionBlock: @escaping (SIMD3<Float>?, SIMD3<Float>?, ARMeshClassification) -> Void) {

        // If there is no frame available, return
        guard let frame = arView.session.currentFrame else {
            completionBlock(nil, nil, .none)
            return
        }

        var meshAnchors = frame.anchors.compactMap { $0 as? ARMeshAnchor }

        // Sort the mesh anchors by distance to the given location and filter out
        // any anchors that are too far away (4 meters is a safe upper limit).
        let cutoffDistance: Float = 4.0
        meshAnchors.removeAll { distance($0.transform.position, location) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, location) < distance($1.transform.position, location) }

        // Perform the search asynchronously in order not to stall rendering.
        DispatchQueue.global().async {
            for anchorIndex in 0..<meshAnchors.count {
                for index in 0..<meshAnchors[anchorIndex].geometry.faces.count {
                    // Get the center of the face so that we can compare it to the given location.
                    let geometricCenterOfFace = meshAnchors[anchorIndex].geometry.centerOf(faceWithIndex: index)

                    // Convert the face's center to world coordinates.
                    var centerLocalTransform = matrix_identity_float4x4
                    centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace[0],
                                                                  geometricCenterOfFace[1],
                                                                  geometricCenterOfFace[2], 1)
                    let centerWorldPosition = (meshAnchors[anchorIndex].transform * centerLocalTransform).position

                    // We're interested in a classification that is sufficiently close to the given location
                    let distanceToFace = distance(centerWorldPosition, location)
                    if distanceToFace <= maxDist {
                        // Get the surface normal
                        let triVerts = meshAnchors[anchorIndex].geometry.verticesOf(faceWithIndex: index)
                        let faceNormal = getTriNormal(pointA: triVerts[0],
                                                      pointB: triVerts[1],
                                                      pointC: triVerts[2])

                        // Get the semantic classification of the face and finish the search.
                        let classification: ARMeshClassification =
                            meshAnchors[anchorIndex].geometry.classificationOf(faceWithIndex: index)
                        completionBlock(centerWorldPosition, faceNormal, classification)
                        return
                    }
                }
            }

            // Let the completion block know that no result was found.
            completionBlock(nil, nil, .none)
        }
    }

    func enableEnvironmentTexturing(_ enable: Bool, force: Bool = false) {
        guard let trackingConfiguration = trackingConfiguration else { return }
        let enabled = trackingConfiguration.environmentTexturing == .automatic
        guard force || enabled != enable else { return }
        trackingConfiguration.environmentTexturing = enable ? .automatic : .none
        arView.session.run(trackingConfiguration)
        log.debug("environmentTexturing %s", "\(enable ? "Enabled" : "Disabled")")
    }

    func enableIBL(_ enable: Bool, _ force: Bool = false) {
        guard let iblResource = self.iblResource else { return }

        let enabled = arView.environment.lighting.resource != nil
        guard force || enabled != enable else { return }
        arView.environment.lighting.resource = enable ? iblResource : nil

        let resource = arView.environment.lighting.resource != nil
                ? "\(arView.environment.lighting.resource!)" : "<nil>"
        log.debug("IBL %s: %s", "\(enable ? "Enabled" : "Disabled")", "\(resource)")
    }

    @IBAction func exitButtonPressed(_ sender: Any) {
        let leaveAction = UIAlertAction(title: NSLocalizedString("Leave", comment: ""), style: .cancel) { _ in
            self.exitGame()
        }
        let stayAction = UIAlertAction(title: NSLocalizedString("Stay", comment: ""), style: .default)
        let actions = [stayAction, leaveAction]

        let localizedTitle = NSLocalizedString("Are you sure you want to leave the game?", comment: "")

        showAlert(title: localizedTitle, message: "", actions: actions)
    }

    private func exitGame() {
        gameManager?.shutdownGame()
        sceneObserver?.cancel()
        sceneObserver = nil
        arView.session.delegate = nil
        arView.scene.anchors.removeAll()
        if let trackingConfiguration = trackingConfiguration {
            trackingConfiguration.planeDetection = []
            trackingConfiguration.environmentTexturing = .none
            arView.session.run(trackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
        }
        dismiss(animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate = nil
        gameManager = nil
        assets = nil
    }

    private func updateLoop(deltaTimeInterval: TimeInterval) {
        delegate?.onSceneUpdated(arView, deltaTimeInterval: deltaTimeInterval)
    }
}

extension GameViewController: OptionsSettingsDelegate {

    func optionsSettingsUpdateCreaturesBaseSpeed() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updateCreaturesBaseSpeed()
    }

    func optionsSettingsUpdateCreatureScale() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updateCreaturesBaseSpeed()
    }

    func optionsSettings(enableDisable: Bool, debugOptions: ARView.DebugOptions) {
        guard let arView = self.arView else {
            return
        }
        arView.updateDebugOptions(debugOptions, enableDisable)
    }

    func optionsSettings(enableDisable: Bool, renderOptions: ARView.RenderOptions) {
        guard let arView = self.arView else {
            return
        }
        arView.updateRenderOptions(renderOptions, enableDisable)
    }

    func optionsSettings(enableDisable: Bool,
                         sceneUnderstandingOptions: ARView.Environment.SceneUnderstanding.Options) {
        guard let arView = self.arView else {
            return
        }
        arView.updateSceneUnderstandingOptions(sceneUnderstandingOptions, enableDisable)
    }

    func optionsSettingsUpdatePathfindingVisuals() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updatePathfindingVisuals()
        messageLabel.text = ""
    }

    func optionsSettingsUpdatePathfindingEnabled() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updatePathfindingEnabled()
    }

    func optionsSettingsUpdateRadarViewVisuals() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updateRadarViewVisuals()
    }

    func optionsSettingsUpdateIBL() {
        enableIBL(Options.enableIBL.value)
    }

    func optionsSettingsUpdateEnvironmentTexturing() {
        enableEnvironmentTexturing(Options.enableEnvironmentTexturing.value)
    }

    func optionsSettingsUpdatePlayPauseVideoMaterials() {
        gameManager?.creaturePool?.enablePlayPauseVideoMaterials(Options.playPauseVideoMaterials.value)
    }

    func optionsSettingsUpdateShaderDebug() {
        guard let gameManager = self.gameManager else { return }
        gameManager.updateShaderDebug()
    }

    func optionsSettingsUpdateCameraExposure() {
        arView.environment.background = .cameraFeed(exposureCompensation: Options.cameraExposure.value)
    }

}
