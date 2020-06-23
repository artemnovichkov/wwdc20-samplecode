/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that loads the game's main user interface.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            if Configuration.showDebugCoreDataView {
                DebugCoreDataView()
            }

            NavigationView {
                MainMenuView()
            }
        }
    }
}
