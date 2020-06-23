/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the menu view.
*/

import SwiftUI

struct MenuView: View {
    @EnvironmentObject var workoutSession: WorkoutManager
    
    @State var workoutPaused: Bool = false // Internal workout state.
    let pauseAction: (() -> Void) // Callback to toggle pausing / resuming a workout.
    let endAction: (() -> Void) // Callback to end a workout.
    
    var body: some View {
        HStack(alignment: .center) {
            // The button that end a workout.
            Spacer()
            MenuButton(title: "End", symbolName: "xmark.circle.fill", action: {
                print("End tapped!")
                self.endAction()
                self.workoutPaused = false
            }).padding(.trailing, 6)
            
            Spacer()
            
            // The button that pauses and resumes a workout.
            MenuButton(title: workoutPaused ? "Resume" : "Pause", symbolName: workoutPaused ? "play.circle.fill" : "pause.circle.fill", action: {
                print("Pause tapped!")
                self.workoutPaused.toggle()
                self.pauseAction()
            }).padding(.leading, 6)
            Spacer()
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var pauseAction = { }
    static var endAction = { }
    
    static var previews: some View {

        Group {
            MenuView(pauseAction: pauseAction, endAction: endAction)
            .previewDevice("Apple Watch Series 3 - 38mm")
            .previewDisplayName("38 mm")
            
            MenuView(pauseAction: pauseAction, endAction: endAction)
            .previewDevice("Apple Watch Series 5 - 40mm")
            .previewDisplayName("40 mm")

            MenuView(pauseAction: pauseAction, endAction: endAction)
            .previewDevice("Apple Watch Series 5 - 44mm")
            .previewDisplayName("44 mm")
        }
        .environmentObject(WorkoutManager())
    }
}
