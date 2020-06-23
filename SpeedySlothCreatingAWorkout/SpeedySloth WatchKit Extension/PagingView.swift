/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the page view that contains the menu view and the workout view.
*/

import SwiftUI

struct PagingView: View {
    // The business logic.
    @EnvironmentObject var workoutSession: WorkoutManager
    // The page you are showing the user.
    @State var pageSelection: PageSelection = .workout
    // Tracks whether a workout is in progress (paused or running), or not.
    @Binding var workoutInProgress: Bool
    
    // Page selection enum.
    enum PageSelection {
        case menu // Show the menu page.
        case workout // Show the workout page.
    }
    
    var body: some View {
        // A Page style tab view.
        TabView(selection: $pageSelection) {
            // The menu view.
            MenuView(pauseAction: pauseAction, endAction: endAction)
                .tag(PageSelection.menu)
            
            // The workout view.
            WorkoutView()
                .tag(PageSelection.workout)
        }.tabViewStyle(PageTabViewStyle())
    }
    
    // Callback provided to the pause menu button.
    func pauseAction() {
        withAnimation { self.pageSelection = .workout }
        workoutSession.togglePause()
    }
    
    // Callback provided to the end workout menu button.
    func endAction() {
        print("PageView got endAction()")
        // End the workout.
        workoutSession.endWorkout()
        
        // Make sure you arrive back on the WorkoutView the next time a workout starts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.pageSelection = .workout
        }
        // Bring up StartView.
        workoutInProgress = false
    }
}

struct PagingView_Previews: PreviewProvider {
    @State static var workoutInProgress = true
    static var previews: some View {
        Group {
            PagingView(pageSelection: .menu, workoutInProgress: $workoutInProgress)
            .previewDisplayName("pageSelection: .menu")
                
            PagingView(pageSelection: .workout, workoutInProgress: $workoutInProgress)
            .previewDisplayName("pageSelection: .workout")
        }
        .environmentObject(WorkoutManager())
    }
}
