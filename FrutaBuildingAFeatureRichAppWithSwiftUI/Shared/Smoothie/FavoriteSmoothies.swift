/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The favorites tab or content list that includes smoothies marked as favorites.
*/

import SwiftUI

struct FavoriteSmoothies: View {
    @EnvironmentObject private var model: FrutaModel

    var favoriteSmooties: [Smoothie] {
        model.favoriteSmoothieIDs.map { Smoothie(for: $0)! }
    }
    
    var body: some View {
        SmoothieList(smoothies: favoriteSmooties)
            .overlay(Group {
                if model.favoriteSmoothieIDs.isEmpty {
                    Text("Add some smoothies to your favorites!")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            })
            .navigationTitle("Favorites")
    }
}

struct FavoriteSmoothies_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteSmoothies()
            .environmentObject(FrutaModel())
    }
}
