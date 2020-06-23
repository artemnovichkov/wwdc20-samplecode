/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the game's main menu.
*/

import CoreData
import SwiftUI
import os

struct MainMenuView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext

    @FetchRequest(fetchRequest: GameEntity.currentGamesFetchRequest()) private var currentGames

    @FetchRequest(fetchRequest: GameEntity.bestGamesFetchRequest()) private var bestGames

    var body: some View {
        GeometryReader { geometry in
            List {
                Section(header: SectionHeaderView { Text("memory ◦ game") }) {
                    makePlayGameView()
                    makeResetCurrentGamesView()
                }

                if !bestGames.isEmpty {
                    Section(header: SectionHeaderView { Text("high ◦ scores") }) {
                        ForEach(bestGames.prefix(1)) {
                            ProminentHighScoreView(game: $0)
                        }

                        ForEach(bestGames.dropFirst().prefix(4)) {
                            StandardHighScoreView(game: $0)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width * 0.4)
            .offset(x: geometry.size.width * 0.3, y: 0)
        }
        .listStyle(GroupedListStyle())
        .navigationBarHidden(true)
    }

    private func makePlayGameView() -> some View {
        Group {
            if let game = currentGames.first {
                NavigationLink("Resume Game", destination: GameView(game: game))
            } else {
                NavigationLink("New Game", destination: NewGameView())
            }
        }
        .font(.system(.body, design: .rounded))
    }

    @ViewBuilder private func makeResetCurrentGamesView() -> some View {
        if Configuration.showResetCurrentGamesButton && !currentGames.isEmpty {
            Button("Reset Current Game", action: resetCurrentGames)
        }
    }

    private func resetCurrentGames() {
        do {
            let request = GameEntity.deleteCurrentGamesRequest()
            request.resultType = .resultTypeObjectIDs

            let result = try managedObjectContext.execute(request) as? NSBatchDeleteResult
            let deleted = result?.result as? [NSManagedObjectID] ?? []

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: deleted],
                into: [managedObjectContext]
            )
        } catch {
            Logger().error("Failed to reset current games. {error=\(error as NSError)}")
        }
    }
}
