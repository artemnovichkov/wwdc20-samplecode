/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays debug information about games loaded from Core Data.
*/

import SwiftUI

struct DebugCoreDataView: View {
    @FetchRequest(fetchRequest: GameEntity.currentGamesFetchRequest()) private var currentGames

    @FetchRequest(fetchRequest: GameEntity.bestGamesFetchRequest()) private var bestGames

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Current Games")

                ForEach(currentGames) {
                    Text($0.description)
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))

                Text("Best Games")

                ForEach(bestGames) {
                    Text($0.description)
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 12))
        .foregroundColor(Color(.systemRed))
        .edgesIgnoringSafeArea(.all)
    }
}
