/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Input System Delegate
*/

import Foundation
import ARKit
import RealityKit

protocol InputSystemDelegate: AnyObject {
    func playerBeganTouch(touchTransform: Transform)
    func playerUpdatedTouchTrail(touchTransform: Transform)
    func playerAchievedWhack()
    func playerAchievedTractorBeam()
    func playerEndedTouch()
}
