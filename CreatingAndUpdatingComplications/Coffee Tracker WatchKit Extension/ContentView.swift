/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A wrapper view that instantiates the coffee tracker view and the data for the hosting controller.
*/

import SwiftUI

// A wrapper view that simplifies adding the main view to the hosting controller.
struct ContentView: View {
    
    // Access the shared model object.
    let data = CoffeeData.shared
    
    // Create the main view, and pass the model.
    var body: some View {
        CoffeeTrackerView()
            .environmentObject(data)
    }
}

// The preview for the content view.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
