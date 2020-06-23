/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the contents for a single game tile.
*/

import SwiftUI

struct TileView: View {
    enum TileState {
        
        /// The tile contents are not visible and no background color is applied.
        case hidden

        /// The tile contents are temporarily visible and no background color is applied.
        case candidate

        /// The tile contents are temporarily visible with a red background color.
        case failed

        /// The tile contents are visible with a green background color.
        case accepted
    }

    @Environment(\.isFocused) private var isFocused

    var sticker: String

    var state: TileState

    var body: some View {
        ZStack {
            isFocused ? Color.clear : Color("tiles/base")

            Image(sticker)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(state != .hidden ? 1 : Configuration.showHiddenTiles ? 0.25 : 0)

            Color.clear
                .border(Color(.systemRed), width: 10)
                .opacity(state == .failed ? 1 : 0)
        }
        .debugBorder(Color(.systemRed))
    }
}
