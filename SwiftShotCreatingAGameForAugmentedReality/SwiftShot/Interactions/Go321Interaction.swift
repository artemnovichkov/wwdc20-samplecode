/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Display "3, 2, 1, Go" in the beginning
*/

import Foundation
import SceneKit

class Go321Interaction: Interaction {
    weak var delegate: InteractionDelegate?
    private var go123: SCNNode

    private let distanceCameraToGoNode: Float = 7.0
    private let go321StartTime = 3.0
    private let go321WaitTime = 2.9

    var musicCoordinator: MusicCoordinator?

    required init(delegate: InteractionDelegate) {
        self.delegate = delegate
        
        // Setup node
        go123 = SCNNode.loadSCNAsset(modelFileName: "321Go")
        delegate.addNodeToLevel(go123)
        go123.simdWorldPosition = SIMD3<Float>(0.0, 5.0, 0.0)

        // Stop animation in the beginnning
        go123.stopAllAnimations()
    }

    func start() {

        guard let musicCoordinator = musicCoordinator else {
            fatalError("Must set musicCoordinator before calling start()")
        }

        let music321name = "music_321_go"
        let musicPlayer = musicCoordinator.musicPlayer(name: music321name)
        let musicDuration = musicPlayer.duration

        go123.setNodeToAlwaysInFront(recursively: true)

        // Queue up the sequence to show 1, 2, 3, GO!
        let initialWaitAction = SCNAction.wait(duration: go321StartTime)
        let goStartAction = SCNAction.run { node in
            
            // Play all the animations
            node.playAllAnimations()

            // Play the music, and start game music after the animation finishes.
            musicCoordinator.playMusic(name: music321name)
        }

        let waitForMusicAction = SCNAction.wait(duration: musicDuration)
        let startGameMusicAction = SCNAction.run { node in
            self.delegate?.startGameMusic(from: self)
        }
        let goWaitTimeAction = SCNAction.wait(duration: go321WaitTime)
        let goEndAction = SCNAction.hide()
        
        go123.runAction(.sequence([
            initialWaitAction,
            .group([
                .sequence([goStartAction, goWaitTimeAction, goEndAction]),
                .sequence([waitForMusicAction, startGameMusicAction])
                ])
            ]))
    }
    
    func update(cameraInfo: CameraInfo) {
        guard !go123.isHidden else { return }
        // Always position the node in front of the camera.
        let ray = cameraInfo.ray
        
        var transform = cameraInfo.transform
        transform.columns.3 += SIMD4<Float>(ray.direction * distanceCameraToGoNode, 0.0)
        let scale = go123.simdScale
        go123.simdWorldTransform = transform
        go123.simdScale = scale
    }

    func handleTouch(_ type: TouchType, camera: Ray) {

    }
}
