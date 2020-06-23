/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows a standard high store for a finished game.
*/

import SwiftUI

struct StandardHighScoreView: View {
    @ObservedObject var game: GameEntity

    private var formattedDuration: String? {
        Configuration.gameDurationFormatter.string(from: game.duration)
    }

    var body: some View {
        formattedDuration.map { Text($0) }
            .font(.system(.body, design: .rounded))
            .frame(maxWidth: .infinity)
    }
}
