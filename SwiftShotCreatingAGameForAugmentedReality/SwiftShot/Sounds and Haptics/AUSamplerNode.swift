/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience wrapper for using MIDI to modulate SFX audio.
*/

import AVFoundation

class AUSamplerNode: AVAudioUnitMIDIInstrument {

    let auSamplerDescription = AudioComponentDescription(componentType: kAudioUnitType_MusicDevice,
                                                         componentSubType: kAudioUnitSubType_Sampler,
                                                         componentManufacturer: kAudioUnitManufacturer_Apple,
                                                         componentFlags: 0,
                                                         componentFlagsMask: 0)

    override init() {
        super.init(audioComponentDescription: auSamplerDescription)
    }
}
