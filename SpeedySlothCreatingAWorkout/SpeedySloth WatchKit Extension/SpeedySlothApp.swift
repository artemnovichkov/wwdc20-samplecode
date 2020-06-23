/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the SpeedySloth app.
*/

import SwiftUI

@main
struct SpeedySlothApp: App {
    // This is the business logic.
    var workoutManager = WorkoutManager()

    // Return the scene.
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(workoutManager)
            }
        }
    }
}
