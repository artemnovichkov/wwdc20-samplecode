/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct that describes playable videos.
*/

import AVKit

struct PlaybackItem {

    enum PlayerKind: Int {
        case avPlayerViewController
        case customPlayerViewController
    }

    enum Video: Int {
        case video1
        case video2

        var itemURL: URL {
            switch self {
            case .video1: return Bundle.main.url(forResource: "video1", withExtension: "m4v")!
            case .video2: return Bundle.main.url(forResource: "video2", withExtension: "m4v")!
            }
        }

        var playerItem: AVPlayerItem {
            return AVPlayerItem(url: itemURL)
        }
    }

    let playerKind: PlayerKind
    let video: Video

    init(indexPath: IndexPath) {
        // The playerKind is the IndexPath section (column in the grid) and the video is the row.
        self.playerKind = PlayerKind(rawValue: indexPath.section)!
        self.video = Video(rawValue: indexPath.row)!
    }
}
