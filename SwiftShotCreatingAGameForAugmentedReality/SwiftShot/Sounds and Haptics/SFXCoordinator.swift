/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages playback of sound effects.
*/

import SceneKit
import AVFoundation
import os.log

private let preloadAudioFiles = [
    "vortex_04",
    "catapult_highlight_on_02",
    "catapult_highlight_off_02"
]

class SFXCoordinator: NSObject {
    private let hapticsGenerator = HapticsGenerator()
    let audioEnvironment: AVAudioEnvironmentNode
    var isStretchPlaying = false
    var timeSinceLastHaptic: Date?
    var prevStretchDistance: Float?
    var highlightedCatapult: Catapult?
    var firstVortexCatapultBreak = true

    var audioPlayers = [String: AVAudioPlayer]()
    let playerQueue = DispatchQueue(label: "SFXCoordinator")
    let loadQueue = DispatchQueue(label: "SFXCoordinator.loading")

    var audioSamplers = [AudioSampler]()
    var timer: DispatchSourceTimer?
    var renderToSimulationTransform = float4x4.identity

    var effectsGain: Float = 1.0

    init(audioEnvironment: AVAudioEnvironmentNode) {
        self.audioEnvironment = audioEnvironment

        super.init()

        loadQueue.async {
            for file in preloadAudioFiles {
                self.prepareAudioFile(name: file)
            }
        }

        // Because the coordinate space is scaled, let's apply some adjustments to the
        // distance attenuation parameters to make the distance rolloff sound more
        // realistic.
        audioEnvironment.distanceAttenuationParameters.referenceDistance = 5
        audioEnvironment.distanceAttenuationParameters.maximumDistance = 40
        audioEnvironment.distanceAttenuationParameters.rolloffFactor = 1
        audioEnvironment.distanceAttenuationParameters.distanceAttenuationModel = .inverse

        updateEffectsVolume()

        // When the route changes, we need to reload our audio samplers because sometimes those
        // audio units are being reset.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange(_:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)

        // Subscribe to notifications of user defaults changing so that we can apply them to
        // sound effects.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDefaultsDidChange(_:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc
    private func handleRouteChange(_ notification: Notification) {
        os_log(.error, "AVAudioSession.routeChangeNotification, info: %s", String(describing: notification.userInfo))
        loadQueue.async {
            os_log(.error, "Reloading AudioSamplers...")
            for sampler in self.audioSamplers {
                sampler.reloadPreset()
            }
            os_log(.error, "done reloading AudioSamplers.")
        }
    }

    @objc
    private func handleDefaultsDidChange(_ notification: Notification) {
        updateEffectsVolume()
    }

    @objc
    private func handleAppDidEnterBackground(_ notification: Notification) {
        for audioSampler in audioSamplers {
            audioSampler.stopAllNotes()
        }
    }

    static func effectsGain() -> Float {
        let effectsVolume = UserDefaults.standard.effectsVolume
        // Map the slider value from 0...1 to a more natural curve:
        return effectsVolume * effectsVolume
    }
    
    func updateEffectsVolume() {
        effectsGain = SFXCoordinator.effectsGain()
        audioEnvironment.outputVolume = effectsGain
    }

    func setupGameAudioComponent(_ component: GameAudioComponent) {
        component.sfxCoordinator = self
    }

    func attachSampler(_ audioSampler: AudioSampler, to node: SCNNode) {
        // Add the audio Player to the scenekit node so that it gets correct positional
        // adjustments
        node.addAudioPlayer(audioSampler.audioPlayer)

        // NOTE: AVAudioNodes that are not AVAudioPlayerNodes are not
        // automatically added to an AVAudioEngine by SceneKit. So we add
        // this audio node to the SCNNode so that it can get position updates
        // but we connect it manually to the AVAudioEnvironmentNode that we
        // get passed to us. This comes from ARSCNView in GameSceneViewController.
        guard let engine = audioEnvironment.engine else {
            os_log(.error, "ERROR: Missing audio engine from audio environment!")
            return
        }
        let audioNode = audioSampler.audioNode
        engine.attach(audioNode)
        let engineFormat = engine.outputNode.inputFormat(forBus: 0)
        let format = AVAudioFormat(standardFormatWithSampleRate: engineFormat.sampleRate, channels: 1)
        engine.connect(audioNode, to: audioEnvironment, format: format)
        audioSamplers.append(audioSampler)
    }

    func removeAllAudioSamplers() {
        guard let engine = audioEnvironment.engine else {
            os_log(.error, "no audio engine")
            return
        }
        
        playerQueue.async {
            for sampler in self.audioSamplers {
                engine.detach(sampler.audioNode)
            }

            self.audioPlayers.removeAll()
        }
    }

    func urlForSound(named name: String) -> URL? {
        for ext in ["wav", "m4a"] {
            let filename = "Sounds/\(name)"
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    func createPlayer(for name: String) -> AVAudioPlayer {
        do {
            guard let url = urlForSound(named: name) else {
                fatalError("Failed to load sound for: \(name)")
            }
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            fatalError("Failed to load sound for: \(name)")
        }
   }

    func prepareAudioFile(name: String) {
        var needsToLoad = false
        playerQueue.sync {
            needsToLoad = (audioPlayers[name] == nil)
        }

        if needsToLoad {
            let player = createPlayer(for: name)
            player.prepareToPlay()
            playerQueue.sync {
                self.audioPlayers[name] = player
            }
        }
    }

    func playAudioFile(name: String, volume: Float = 1.0, loop: Bool = false) {
        playerQueue.sync {
            var player = audioPlayers[name]
            if player == nil {
                player = createPlayer(for: name)
                audioPlayers[name] = player
            }
            if let player = player {
                player.volume = volume * effectsGain
                player.play()
                if loop {
                    player.numberOfLoops = -1
                }
            }
        }
    }

    func stopAudioFile(name: String, fadeDur: Double) {
        playerQueue.sync {
            if let player = audioPlayers[name] {
                player.setVolume(0.0, fadeDuration: fadeDur)
                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDur) {
                    player.stop()
                }
            }
        }
    }

    func playStretch(catapult: Catapult, stretchDistance: Float, stretchRate: Float, playHaptic: Bool) {
        let normalizedDistance = clamp((stretchDistance - 0.1) / 2.0, 0.0, 1.0)

        if isStretchPlaying {
            // Set the stretch distance and rate on the audio
            // player to module the strech sound effect.
            catapult.audioPlayer.stretchDistance = normalizedDistance
            catapult.audioPlayer.stretchRate = stretchRate
        } else {
            catapult.audioPlayer.startStretch()
            isStretchPlaying = true
        }
        guard playHaptic else { return }

        let interval: TimeInterval
        switch normalizedDistance {
        case 0.25...0.50:
            interval = 0.5
        case 0.5...:
            interval = 0.25
        default:
            interval = 1.0
        }
        if let prevStretchDistance = prevStretchDistance {
            let delta = abs(stretchDistance - prevStretchDistance)
            self.prevStretchDistance = stretchDistance
            if delta < 0.0075 {
                return
            }
        } else {
            prevStretchDistance = stretchDistance
        }
        if let prevTime = timeSinceLastHaptic {
            if Date().timeIntervalSince(prevTime) > interval {
                hapticsGenerator.generateImpactFeedback()
                timeSinceLastHaptic = Date()
            }
        } else {
            hapticsGenerator.generateImpactFeedback()
            timeSinceLastHaptic = Date()
        }
    }
    
    func stopStretch(catapult: Catapult) {
        catapult.audioPlayer.stopStretch()
        catapult.audioPlayer.stretchDistance = 0
        isStretchPlaying = false
        timeSinceLastHaptic = nil
    }
    
    func playLaunch(catapult: Catapult, velocity: GameVelocity, playHaptic: Bool) {
        if playHaptic {
            hapticsGenerator.generateNotificationFeedback(.success)
        }
        catapult.audioPlayer.playLaunch(velocity: velocity)
    }

    func playGrabBall(catapult: Catapult) {
        catapult.audioPlayer.playGrabBall()
        // clear the highlight state so we don't play the highlight off
        // sound after the player has grabbed the ball.
        highlightedCatapult = nil
    }

    func catapultDidChangeHighlight(_ catapult: Catapult, highlighted: Bool) {
        if highlighted {
            if highlightedCatapult !== catapult {
                catapult.audioPlayer.playHighlightOn()
                highlightedCatapult = catapult
            }
        } else {
            if highlightedCatapult === catapult {
                catapult.audioPlayer.playHighlightOff()
                highlightedCatapult = nil
            }
        }
    }

    func playCatapultBreak(catapult: Catapult, vortex: Bool) {
        os_log(.info, "play catapult break for catapultID = %d", catapult.catapultID)

        var shouldPlay = true
        if vortex {
            if firstVortexCatapultBreak {
                firstVortexCatapultBreak = false
            } else {
                shouldPlay = false
            }
        }
        if shouldPlay {
            catapult.audioPlayer.playBreak()
        }
    }

    func playLeverHighlight(highlighted: Bool) {
        if highlighted {
            playAudioFile(name: "catapult_highlight_on_02", volume: 0.2)
        } else {
            playAudioFile(name: "catapult_highlight_off_02", volume: 0.2)
        }
    }
}
