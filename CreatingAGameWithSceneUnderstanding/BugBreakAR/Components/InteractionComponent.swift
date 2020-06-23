/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Interaction Component
*/

import Foundation
import RealityKit
import ARKit

public struct InteractionComponent: Component {
    var isWhackable: Bool = false
    weak var delegate: InteractionComponentDelegate?

    fileprivate let tractorBeamAnimationTime: Float = 0.25
    fileprivate var tractorBeamLight: PointLight!
    fileprivate var whackRangeLight: PointLight!
    fileprivate let pointLightIntensity: Float = 500_000
    // The point light is hard to see after this distance from Creature:
    fileprivate let pointLightMaxDistance = Float(0.365)
    fileprivate var timer: Float = 0.0
}

public protocol InteractionComponentDelegate: AnyObject {
    func released()
    func whacked()
    func tractorBeamed()
}

public protocol HasInteraction where Self: Entity {}

public extension HasInteraction where Self: Entity {
    var interaction: InteractionComponent {
        get { return components[InteractionComponent.self] ?? InteractionComponent() }
        set { components[InteractionComponent.self] = newValue }
    }

    func setupInteractiveLights() {
        // Tractor beam cyan light
        interaction.tractorBeamLight = PointLight()
        let tractorBeamLightComponent = PointLightComponent(color: .cyan,
                                                            intensity: interaction.pointLightIntensity,
                                                            attenuationRadius: 0.125)
        interaction.tractorBeamLight.components.set(tractorBeamLightComponent)
        self.addChild(interaction.tractorBeamLight)
        interaction.tractorBeamLight.position = SIMD3<Float>(0, Constants.creatureShape.y / 3, 0)
        interaction.tractorBeamLight.isEnabled = false

        // Whack range red light
        interaction.whackRangeLight = PointLight()
        let whackRangeLightComponent = PointLightComponent(color: .red,
                                                           intensity: interaction.pointLightIntensity,
                                                           attenuationRadius: 0.25)
        interaction.whackRangeLight.components.set(whackRangeLightComponent)
        self.addChild(interaction.whackRangeLight)
        interaction.whackRangeLight.isEnabled = false
    }

    func updateWhackableStatus(_ isWhackable: Bool) {
        // Update stored state
        interaction.isWhackable = isWhackable
        // Update visuals
        interaction.whackRangeLight.isEnabled = isWhackable
        // We'll check how far it is
        let creatureDistanceFromPlayer = fromCameraToCreature()
        // Light should be halfway from Creature to Camera, giving
        // us a nice radius shrink/growth depending on proximity
        let halfwayPointDistance = distanceToCamera() / 2
        if halfwayPointDistance > interaction.pointLightMaxDistance {
            let maxDistPos = self.position(relativeTo: nil) +
                (-normalize(creatureDistanceFromPlayer) * interaction.pointLightMaxDistance)
            interaction.whackRangeLight.setPosition(maxDistPos, relativeTo: nil)
        } else {
            let halfwayPos = AnchorEntity(.camera).transform.translation +
                (creatureDistanceFromPlayer * 0.5)
            interaction.whackRangeLight.setPosition(halfwayPos, relativeTo: nil)
        }
    }

    func enableTractorBeamLight(_ value: Bool) {
        interaction.tractorBeamLight.isEnabled = value
    }

    private func hasEnoughFearToTurnAway() -> Bool {
        // The Camera is the Player
        return distanceToCamera() <= Options.innerFearRadius.value
    }

    private func distanceToCamera() -> Float {
        return distance(AnchorEntity(.camera).transform.translation,
                        position(relativeTo: nil))
    }

    private func fromCameraToCreature() -> SIMD3<Float> {
        return self.position(relativeTo: nil) -
            AnchorEntity(.camera).transform.translation
    }

    // Fling, Drop
    func release(gestureVelocity: SIMD3<Float>) {
        // Release creature
        let camAnchor = AnchorEntity(.camera)
        if let physicsEntity = self as? HasPhysics {
            physicsEntity.physicsBody?.mode = .dynamic
            physicsEntity.addForce(gestureVelocity, relativeTo: camAnchor)
        }

        interaction.delegate?.released()
    }

    func whack() {
        interaction.delegate?.whacked()
    }

    func updateTractorBeamReelIn(deltaTime: Float, entityPosition: SIMD3<Float>) {
        if interaction.timer < interaction.tractorBeamAnimationTime {
            let progress = interaction.timer / interaction.tractorBeamAnimationTime
            setPosition(lerp(vectorA: position(relativeTo: nil),
                             vectorB: entityPosition,
                             timeInterval: progress), relativeTo: nil)
            interaction.timer += deltaTime
        } else {
            interaction.delegate?.tractorBeamed()
        }
    }

    func updateCarriedState(_ entityPosition: SIMD3<Float>) {
        setPosition(entityPosition, relativeTo: nil)
    }

    func tractorBeam() {
        // Begin Tractor Beam Reel in
        interaction.timer = 0
        interaction.tractorBeamLight?.isEnabled = Options.tractorBeamLight.value
    }

    func shutdownInteraction() {
        interaction.tractorBeamLight = nil
        interaction.whackRangeLight = nil
    }
}
