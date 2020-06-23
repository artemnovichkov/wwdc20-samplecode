/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays a game and allows the user to select tiles to find matching images.
*/

import os
import SwiftUI

struct GameView: View {
    private enum SelectedState {

        /// No tiles are currently selected.
        case none

        /// One candidate tile has been selected.
        case candidate(TileEntity)

        /// Two tiles were selected that don't match.
        case failed(TileEntity, TileEntity)
    }

    @Environment(\.managedObjectContext) private var managedObjectContext

    @ObservedObject var game: GameEntity

    @State private var state = SelectedState.none

    var body: some View {
        DynamicFetchRequestView(request: tilesFetchRequest) { tiles in
            LazyVGrid(columns: Self.columns) {
                ForEach(tiles) { tile in
                    cell(for: tile)
                }
            }
        }
        .onDisappear(perform: managedObjectContext.rollback)
        .navigationBarHidden(true)
    }

    private var tilesFetchRequest: FetchRequest<TileEntity> {
        FetchRequest(
            entity: TileEntity.entity(),
            sortDescriptors: [NSSortDescriptor(key: "position", ascending: true)],
            predicate: NSPredicate(format: "game == %@", game)
        )
    }

    private static var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(Configuration.tileSize)), count: Configuration.columns)
    }

    private func cell(for tile: TileEntity) -> some View {
        Button { select(tile) } label: {
            TileView(sticker: tile.wrappedSticker, state: state(for: tile))
                .frame(width: Configuration.tileSize, height: Configuration.tileSize)
        }
        .buttonStyle(PlainButtonStyle())
        .debugBorder(Color.green, width: 5)
    }

    private func select(_ tile: TileEntity) {
        if tile.flipped {
            return
        }

        withAnimation(.spring()) {
            if case .none = state {
                state = .candidate(tile)
            } else if case let .candidate(candidate) = state, candidate != tile {
                if candidate.sticker == tile.sticker {
                    candidate.flipped = true
                    tile.flipped = true

                    game.touch()

                    save()

                    state = .none
                } else {
                    state = .failed(candidate, tile)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring()) { state = .none }
                    }
                }
            }
        }
    }

    private func state(for tile: TileEntity) -> TileView.TileState {
        if tile.flipped {
            return .accepted
        }

        if case let .candidate(candidate) = state, candidate == tile {
            return .candidate
        }

        if case let .failed(first, second) = state, first == tile || second == tile {
            return .failed
        }

        return .hidden
    }

    private func save() {
        do {
            try managedObjectContext.save()
        } catch {
            Logger().error("Failed to save managed object context. {error=\(error as NSError)}")
        }
    }
}
