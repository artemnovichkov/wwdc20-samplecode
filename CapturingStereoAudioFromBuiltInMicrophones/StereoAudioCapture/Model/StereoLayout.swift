/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An enum describing the data source's orientation and the session's input orientation.
*/

import Foundation
import AVFoundation

enum StereoLayout: String {
    
    case none                    = "none"
    case mono                    = "Mono"
    case frontLandscapeLeft      = "Front LandscapeLeft"
    case frontLandscapeRight     = "Front LandscapeRight"
    case frontPortrait           = "Front Portrait"
    case frontPortraitUpsideDown = "Front PortraitUpsideDown"
    case backLandscapeLeft       = "Back LandscapeLeft"
    case backLandscapeRight      = "Back LandscapeRight"
    case backPortrait            = "Back Portrait"
    case backPortraitUpsideDown  = "Back PortraitUpsideDown"
    
    init(orientation: AVAudioSession.Orientation, stereoOrientation: AVAudioSession.StereoOrientation) {
        
        let front = AVAudioSession.Location.orientationFront.rawValue
        let back = AVAudioSession.Location.orientationBack.rawValue
        
        switch (orientation.rawValue, stereoOrientation) {
            
            // Front
            case (front, .none):
                self.init(rawValue: StereoLayout.mono.rawValue)!
                
            case (front, .landscapeLeft):
                self.init(rawValue: StereoLayout.frontLandscapeLeft.rawValue)!
                
            case (front, .landscapeRight):
                self.init(rawValue: StereoLayout.frontLandscapeRight.rawValue)!
                
            case (front, .portrait):
                self.init(rawValue: StereoLayout.frontPortrait.rawValue)!
                
            case (front, .portraitUpsideDown):
                self.init(rawValue: StereoLayout.frontPortraitUpsideDown.rawValue)!
                
            // Back
            case (back, .none):
                self.init(rawValue: StereoLayout.mono.rawValue)!
                
            case (back, .landscapeLeft):
                self.init(rawValue: StereoLayout.backLandscapeLeft.rawValue)!
                
            case (back, .landscapeRight):
                self.init(rawValue: StereoLayout.backLandscapeRight.rawValue)!
                
            case (back, .portrait):
                self.init(rawValue: StereoLayout.backPortrait.rawValue)!
                
            case (back, .portraitUpsideDown):
                self.init(rawValue: StereoLayout.backPortraitUpsideDown.rawValue)!
                
            default:
                self.init(rawValue: StereoLayout.none.rawValue)!
        }
    }
}
