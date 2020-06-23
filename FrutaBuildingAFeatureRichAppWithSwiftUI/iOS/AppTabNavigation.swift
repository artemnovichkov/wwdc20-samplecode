/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's navigation with a configuration that offers four tabs for horizontally compressed environments
*/

import SwiftUI

// MARK: - AppTabNavigation

struct AppTabNavigation: View {
    @State private var selection: Tab = .menu

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                SmoothieMenu()
            }
            .tabItem {
                Label("Menu", systemImage: "list.bullet")
                    .accessibility(label: Text("Menu"))
            }
            .tag(Tab.menu)
            
            NavigationView {
                FavoriteSmoothies()
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
                    .accessibility(label: Text("Favorites"))
            }
            .tag(Tab.favorites)
            
            NavigationView {
                RewardsView()
            }
            .tabItem {
                Label("Rewards", systemImage: "seal.fill")
                    .accessibility(label: Text("Rewards"))
            }
            .tag(Tab.rewards)
            
            NavigationView {
                RecipeList()
            }
            .tabItem {
                Label("Recipes", systemImage: "book.closed.fill")
                    .accessibility(label: Text("Recipes"))
            }
            .tag(Tab.recipes)
        }
    }
}

// MARK: - Tab

extension AppTabNavigation {
    enum Tab {
        case menu
        case favorites
        case rewards
        case recipes
    }
}

// MARK: - Previews

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppTabNavigation()
    }
}
