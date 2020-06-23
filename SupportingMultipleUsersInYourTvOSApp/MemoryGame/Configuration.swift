/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A set of configuration options used by the game.
*/

import SwiftUI

enum Configuration {
    static let rows = 4

    static let columns = 5

    static let tileSize = 175 as CGFloat

    static let gameDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad

        return formatter
    }()

    static let gameCreatedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        return formatter
    }()

    /// Whether the contents of hidden tiles should be visible when debugging.
    #if DEBUG
    static let showHiddenTiles = UserDefaults.standard.bool(forKey: "ShowHiddenTiles")
    #else
    static let showHiddenTiles = false
    #endif

    /// Whether the main menu should show debug options.
    #if DEBUG
    static let showResetCurrentGamesButton = UserDefaults.standard.bool(forKey: "ShowResetCurrentGames")
    #else
    static let showResetCurrentGamesButton = false
    #endif

    /// Whether the main menu should show debug options.
    #if DEBUG
    static let showDebugCoreDataView = UserDefaults.standard.bool(forKey: "ShowDebugCoreDataView")
    #else
    static let showDebugCoreDataView = false
    #endif

    /// Whether debug borders should be drawn around supported views.
    #if DEBUG
    static let showDebugBorders = UserDefaults.standard.bool(forKey: "ShowDebugBorders")
    #else
    static let showDebugBorders = false
    #endif
}
