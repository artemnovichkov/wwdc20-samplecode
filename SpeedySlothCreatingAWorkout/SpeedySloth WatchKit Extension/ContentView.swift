/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the main view of the app, including the animation between the start view, the workout view, and the menu view.
*/

import SwiftUI

struct ContentView: View {
    // Get the business logic from the environment.
    @EnvironmentObject var workoutSession: WorkoutManager
    
    // This view will show an overlay when we don't have a workout in progress.
    @State var workoutInProgress = false
    
    // We need the screen height to know how far to offset the RUN button when the workout is in progress.
    let screenHeight = WKInterfaceDevice.current().screenBounds.size.height
    
    var body: some View {
        PagingView(workoutInProgress: self.$workoutInProgress)
        .opacity(self.workoutInProgress ? 1 : 0)
        .animation(.easeInOut(duration: 0.3))
        .overlay( // Overlay the StartView when a workout is not in progress.
            StartView(startAction: startAction)
                .offset(CGSize(width: 0, height: self.workoutInProgress ? self.screenHeight : 0))
                .animation(.easeInOut(duration: 0.3)))
    }
    
    func startAction() {
        workoutSession.startWorkout()
        withAnimation {
            workoutInProgress = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            .previewDevice("Apple Watch Series 2 - 40mm")
            .previewDisplayName("40 mm")
            
            ContentView()
            .previewDevice("Apple Watch Series 2 - 44mm")
            .previewDisplayName("44 mm")
        }
        .environmentObject(WorkoutManager())
    }
}
