/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main entry point for the game.
*/

import SwiftUI

@main struct MemoryGameApp: App {
    @StateObject private var store = CoreDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, store.viewContext)
        }
    }
}
