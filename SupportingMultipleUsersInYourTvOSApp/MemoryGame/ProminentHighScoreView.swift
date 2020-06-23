/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays a prominent high score for a finished game.
*/

import SwiftUI

struct ProminentHighScoreView: View {
    @ObservedObject var game: GameEntity

    private var crownImage: UIImage? {
        let image = UIImage(systemName: "crown.fill")?
            .withAlignmentRectInsets(.zero)
            .withConfiguration(UIImage.SymbolConfiguration(textStyle: .headline))
            .withRenderingMode(.alwaysTemplate)

        return image
    }

    private var formattedDuration: String? {
        Configuration.gameDurationFormatter.string(from: game.duration)
    }

    private var formattedStartDate: String? {
        game.createdDate.map { Configuration.gameCreatedDateFormatter.string(from: $0) }
    }

    var body: some View {
        VStack(spacing: 8) {
            crownImage.map { Image(uiImage: $0) }
                .foregroundColor(Color(.systemYellow))

            formattedDuration.map { Text($0) }
                .font(.system(.largeTitle, design: .rounded))

            formattedStartDate.map { Text($0) }
                .font(.system(.body, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
