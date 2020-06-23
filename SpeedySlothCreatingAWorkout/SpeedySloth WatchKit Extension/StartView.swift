/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This file defines the start view, where the user can start a workout.
*/

import SwiftUI
import Combine

struct StartView: View {
    
    @EnvironmentObject var workoutSession: WorkoutManager
    
    let startAction: (() -> Void)? // The start action callback.
    
    var body: some View {
        RunButton(action: {
            self.startAction!() // FixMe!
        }).onAppear() {
            // Request HealthKit store authorization.
            self.workoutSession.requestAuthorization()
        }
    }
}

struct InitialView_Previews: PreviewProvider {
    static var startAction = { }
    
    static var previews: some View {
        StartView(startAction: startAction)
        .environmentObject(WorkoutManager())
    }
}
