/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that lazily creates a new game when its contents are displayed.
*/

import SwiftUI

struct NewGameView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext

    @State private var game: GameEntity?

    var body: some View {
        Group {
            game.map { GameView(game: $0) }
        }
        .onAppear {
            if game == nil {
                game = makeNewGame()
            }
        }
    }

    private func makeNewGame() -> GameEntity {
        let game = GameEntity(context: managedObjectContext)
        game.createdDate = Date()

        var stickers = [Sticker]()
        stickers.append(contentsOf: Sticker.all)
        stickers.append(contentsOf: Sticker.all)

        assert(stickers.count == Configuration.columns * Configuration.rows)

        stickers.shuffled().enumerated().forEach { position, sticker in
            let tile = TileEntity(context: managedObjectContext)
            
            tile.game = game
            tile.wrappedPosition = position
            tile.wrappedSticker = sticker.image
        }

        return game
    }
}
