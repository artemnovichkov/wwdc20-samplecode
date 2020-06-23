/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages playback and volume of music.
*/

import AVFoundation
import os.log

class MusicCoordinator: NSObject {

    enum MusicState {
        case stopped
        case playing
        case stopping // transition from play to stop, fading out.
    }

    struct MusicConfig: Codable {
        let filename: String
        let volumeDB: Float
        let loops: Bool
    }

    class MusicPlayer {
        let name: String
        let audioPlayer: AVAudioPlayer
        let config: MusicConfig
        var state: MusicState

        init(name: String, config: MusicConfig) {
            self.name = name
            self.config = config
            self.state = .stopped
            guard let url = Bundle.main.url(forResource: config.filename, withExtension: nil) else {
                fatalError("Failed to load sound for: \(name) expected at: \(config.filename)")
            }
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            } catch {
                fatalError("Failed to load sound for: \(name) expected at: \(config.filename)")
            }
        }

        var duration: TimeInterval {
            return audioPlayer.duration
        }
    }

    var musicGain: Float = 1.0
    var musicPlayers = [String: MusicPlayer]()
    var musicConfigurations = [String: MusicConfig]()
    var currentMusicPlayer: MusicPlayer?

    static let defaultFadeOut = TimeInterval(0.2)

    override init() {
        super.init()

        updateMusicVolume()

        do {
            guard let url = Bundle.main.url(forResource: "Sounds/music.json", withExtension: nil) else {
                fatalError("Failed to load music config from Sounds/music.json")
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            musicConfigurations = try decoder.decode([String: MusicConfig].self, from: data)
        } catch {
            fatalError("Failed to load music config from Sounds/music.json")
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDefaultsDidChange(_:)),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    @objc
    private func handleDefaultsDidChange(_ notification: Notification) {
        updateMusicVolume()
    }

    func updateMusicVolume() {
        let volume = UserDefaults.standard.musicVolume
        // Map the slider value from 0...1 to a more natural curve:
        musicGain = volume * volume

        for (_, player) in musicPlayers where player.state == .playing {
            let volume = clamp(musicGain * pow(10, player.config.volumeDB / 20.0), 0, 1)
            player.audioPlayer.setVolume(volume, fadeDuration: 0.1)
        }
    }

    /// Get the current play position for the currently playing music
    /// returns time in seconds, or -1 if nothing is playing.
    func currentMusicTime() -> TimeInterval {
        if let currentMusicPlayer = currentMusicPlayer {
            return currentMusicPlayer.audioPlayer.currentTime
        } else {
            return -1
        }
    }

    func musicPlayer(name: String) -> MusicPlayer {
        if let player = musicPlayers[name] {
            return player
        }

        guard let config = musicConfigurations[name] else {
            fatalError("Missing music config for music event named '\(name)'")
        }
        let player = MusicPlayer(name: name, config: config)
        musicPlayers[name] = player
        return player
    }

    @discardableResult
    func playMusic(name: String, fadeIn: TimeInterval = 0.0) -> MusicPlayer {
        return playMusic(name: name, startTime: 0, fadeIn: fadeIn)
    }

    @discardableResult
    func playMusic(name: String, startTime: TimeInterval, fadeIn: TimeInterval = 0.0) -> MusicPlayer {
        let player = musicPlayer(name: name)
        let audioPlayer = player.audioPlayer

        if let currentMusicPlayer = currentMusicPlayer {
            stopMusic(player: currentMusicPlayer)
        }

        os_log(.debug, "playMusic '%s' startTime=%f", name, startTime)

        switch player.state {
        case .playing:
            // Nothing to do
            return player
        case .stopped:
            // Configure the audioPlayer, starting with volume at 0 and then fade in.
            audioPlayer.volume = 0
            audioPlayer.currentTime = 0
            if player.config.loops {
                audioPlayer.numberOfLoops = -1
            } else {
                audioPlayer.numberOfLoops = 0
            }

            audioPlayer.currentTime = startTime
            audioPlayer.play()
        case .stopping:
            // Leave it playing. Update the volume and play state below.
            break
        }

        let volume = clamp(musicGain * pow(10, player.config.volumeDB / 20.0), 0, 1)
        audioPlayer.setVolume(volume, fadeDuration: fadeIn)

        player.state = .playing
        currentMusicPlayer = player

        return player
    }

    func stopMusic(name: String, fadeOut: Double = MusicCoordinator.defaultFadeOut) {
        let player = musicPlayer(name: name)
        stopMusic(player: player, fadeOut: fadeOut)
    }

    func stopCurrentMusic(fadeOut: TimeInterval = MusicCoordinator.defaultFadeOut) {
        if let player = currentMusicPlayer {
            stopMusic(player: player, fadeOut: fadeOut)
        }
    }

    func stopMusic(player: MusicPlayer, fadeOut: TimeInterval = MusicCoordinator.defaultFadeOut) {
        if player.state == .playing {
            os_log(.debug, "stopMusic '%s'", player.name)
            player.state = .stopping
            let audioPlayer = player.audioPlayer
            audioPlayer.setVolume(0.0, fadeDuration: fadeOut)
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOut) {
                if player.state == .stopping {
                    audioPlayer.stop()
                    player.state = .stopped
                }
            }
        }
    }
}
