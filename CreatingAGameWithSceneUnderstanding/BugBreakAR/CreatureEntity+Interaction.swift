/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Entity Interaction
*/

import Foundation
import RealityKit
import ARKit

extension CreatureEntity: HasInteraction, InteractionComponentDelegate {

    public func configureInteraction() {
        interaction = InteractionComponent()
        interaction.delegate = self
    }

    func activateTractorBeam() {
        // Clean up current state
        if currentState == .pathfinding {
            pathfinding.stopPathfinding()
        } else {
            resetPhysics()
            physicsBody?.mode = .kinematic
        }
        // Begin Tractor Beam Reel in
        tractorBeam()
        playSound(name: Constants.struggleAudioName)
        currentState = .tractorBeamReelIn
        setAnimation(animation: .fluttering)
    }

    public func isTractorBeamable() -> Bool {
        guard let playerDistance = distanceToCamera() else { return false }
        return playerDistance <= Options.tractorBeamDistance.value &&
        currentState == .pathfinding || currentState == .none
    }

    public func updateWhackableStatus() {
        guard let distanceSqr = distanceToCameraSquared() else { return }
        let isCloseEnoughToCreature = distanceSqr <= Options.whackDistanceSqr.value
        let isRotatedEnoughTowardsCreature = isCameraFacingCreature()
        let isInWhackableState = currentState == .pathfinding
        updateWhackableStatus(isRotatedEnoughTowardsCreature &&
                                isCloseEnoughToCreature &&
                                isInWhackableState)
    }

    public func whacked() {
        destroyCreature()
    }

    public func tractorBeamed() {
        currentState = .tractorBeamed
        if let audio = gameManager?.assets?.audioResources[Constants.tractorBeamLoopAudioName] {
            gameManager?.audioAnchor?.playAudio(audio)
        }
        setAnimation(animation: .fluttering)
    }

    public func released() {
        // Remove tractor beam light
        if currentState == .tractorBeamed || currentState == .tractorBeamReelIn {
            enableTractorBeamLight(false)
        }

        currentState = .released
        setAnimation(animation: .fluttering)
    }
}
