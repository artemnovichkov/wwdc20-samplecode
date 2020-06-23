/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The object that controls and configures the app's audio behavior.
*/

import Foundation
import AVFoundation

protocol AudioControllerDelegate: AnyObject {
    func audioControllerDidStopPlaying()
}

// Enum to normalize UIInterfaceOrientation and AVAudioSession.StereoOrientation.
enum Orientation: Int {
    case unknown = 0
    case portrait = 1
    case portraitUpsideDown = 2
    case landscapeLeft = 4
    case landscapeRight = 3
}

fileprivate extension Orientation {
    // Convenience property to retrieve the AVAudioSession.StereoOrientation.
    var inputOrientation: AVAudioSession.StereoOrientation {
        return AVAudioSession.StereoOrientation(rawValue: rawValue)!
    }
}

enum AudioControllerState {
    case stopped
    case playing
    case recording
}

struct RecordingOption: Comparable {
    let name: String
    fileprivate let dataSourceName: String
    static func < (lhs: RecordingOption, rhs: RecordingOption) -> Bool {
        lhs.name < rhs.name
    }
}

class AudioController: NSObject, StereoLevelsProvider {
    
    private var isStereoSupported = false {
        didSet {
            setupRecorder()
        }
    }
    
    static var recordingOptions: [RecordingOption] = {
        // Names of the required data sources.
        let front = AVAudioSession.Location.orientationFront.rawValue
        let back = AVAudioSession.Location.orientationBack.rawValue
        let bottom = AVAudioSession.Location.orientationBottom.rawValue

        let session = AVAudioSession.sharedInstance()
        guard let dataSources = session.preferredInput?.dataSources else { return [] }
        
        var options = [RecordingOption]()
        dataSources.forEach { dataSource in
            switch dataSource.dataSourceName {
                case front:
                    options.append(RecordingOption(name: "Front Stereo", dataSourceName: front))
                case back:
                    options.append(RecordingOption(name: "Back Stereo", dataSourceName: back))
                case bottom:
                    options.append(RecordingOption(name: "Mono", dataSourceName: bottom))
                default: ()
            }
        }
        // Sort alphabetically
        options.sort()
        return options
    }()
    
    var isDeviceSupported: Bool {
        return AudioController.recordingOptions.count >= 3
    }
    
    weak var delegate: AudioControllerDelegate?
    
    private var player: AVAudioPlayer?
    private var recorder: AVAudioRecorder!
    
    typealias RecordStopHandler = (Bool) -> Void
    private var stopHandler: RecordStopHandler?
    
    private var audioURL: URL?
    private let meterTable = MeterTable()
    
    private var timer: Timer?
    private(set) var state = AudioControllerState.stopped
    
    override init() {
        super.init()
        setupRecorder()
        setupAudioSession()
        enableBuiltInMic()
    }
    
    // MARK: - Audio Session Configuration
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            fatalError("Failed to configure and activate session.")
        }
    }
    
    private func enableBuiltInMic() {
        // Get the shared audio session.
        let session = AVAudioSession.sharedInstance()
        
        // Find the built-in microphone input.
        guard let availableInputs = session.availableInputs,
              let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            print("The device must have a built-in microphone.")
            return
        }
        
        // Make the built-in microphone input the preferred input.
        do {
            try session.setPreferredInput(builtInMicInput)
        } catch {
            print("Unable to set the built-in mic as the preferred input.")
        }
    }
    
    func selectRecordingOption(_ option: RecordingOption, orientation: Orientation, completion: (StereoLayout) -> Void) {
        
        // Get the shared audio session.
        let session = AVAudioSession.sharedInstance()
        
        // Find the built-in microphone input's data sources,
        // and select the one that matches the specified name.
        guard let preferredInput = session.preferredInput,
              let dataSources = preferredInput.dataSources,
              let newDataSource = dataSources.first(where: { $0.dataSourceName == option.dataSourceName }),
              let supportedPolarPatterns = newDataSource.supportedPolarPatterns else {
            completion(.none)
            return
        }
        
        do {
            isStereoSupported = supportedPolarPatterns.contains(.stereo)
            // If the data source supports stereo, set it as the preferred polar pattern.
            if isStereoSupported {
                // Set the preferred polar pattern to stereo.
                try newDataSource.setPreferredPolarPattern(.stereo)
            }

            // Set the preferred data source and polar pattern.
            try preferredInput.setPreferredDataSource(newDataSource)
            
            // Update the input orientation to match the current user interface orientation.
            try session.setPreferredInputOrientation(orientation.inputOrientation)

        } catch {
            fatalError("Unable to select the \(option.dataSourceName) data source.")
        }
        
        // Call the completion handler with the updated stereo layout.
        completion(StereoLayout(orientation: newDataSource.orientation!,
                                stereoOrientation: session.inputOrientation))
    }

    // MARK: - Audio Recording and Playback
    
    func setupRecorder() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempDir.appendingPathComponent("recording.wav")

        do {
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVLinearPCMIsNonInterleaved: false,
                AVSampleRateKey: 44_100.0,
                AVNumberOfChannelsKey: isStereoSupported ? 2 : 1,
                AVLinearPCMBitDepthKey: 16
            ]
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        } catch {
            fatalError("Unable to create audio recorder: \(error.localizedDescription)")
        }
        
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
    }
    
    @discardableResult
    func record() -> Bool {
        let started = recorder.record()
        state = .recording
        return started
    }
    
    // Stops recording and calls the completion callback when the recording finishes.
    func stopRecording() {
        recorder.stop()
        state = .stopped
    }
    
    func play() {
        guard let url = audioURL else { print("No recording to play"); return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.isMeteringEnabled = true
        player?.delegate = self
        player?.play()
        state = .playing
    }
    
    func stopPlayback() {
        player?.stop()
        state = .stopped
    }
    
    var levels: StereoChannelLevels {

        var meterable: Meterable?
        
        var levels = [ChannelLevels]()
        
        if recorder.isRecording {
            recorder.updateMeters()
            meterable = recorder
        } else if let player = player, player.isPlaying {
            player.updateMeters()
            meterable = player
        }
        
        // Calculate power levels for left and right channels.
        if let meterable = meterable {
            for i in 0...1 {
                let avgPower = meterable.averagePower(forChannel: i)
                let peakPower = meterable.peakPower(forChannel: i)
                
                let linearLevel = meterTable.valueForPower(avgPower)
                let linearPeakLevel = meterTable.valueForPower(peakPower)
                
                levels.append(ChannelLevels(level: linearLevel, peakLevel: linearPeakLevel))
            }
            return StereoChannelLevels(left: levels.first!, right: levels.last!)
        }
        
        return .zero
    }
    
    var recordingURL: URL? {
        let url = FileManager.default.urlInDocumentsDirectory(named: "recording.wav")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

// MARK: - AudioController Extensions
extension AudioController: AVAudioRecorderDelegate {
    
    // AVAudioRecorderDelegate method.
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        let destURL = FileManager.default.urlInDocumentsDirectory(named: "recording.wav")
        try? FileManager.default.removeItem(at: destURL)
        try? FileManager.default.copyItem(at: recorder.url, to: destURL)
        recorder.prepareToRecord()
        
        audioURL = destURL
    }
}

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.audioControllerDidStopPlaying()
    }
}

// Adapter interface for player and recorder.
protocol Meterable {
    func updateMeters()
    func peakPower(forChannel channelNumber: Int) -> Float
    func averagePower(forChannel channelNumber: Int) -> Float
}

extension AVAudioRecorder: Meterable {}
extension AVAudioPlayer: Meterable {}
