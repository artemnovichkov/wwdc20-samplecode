/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the app.
*/

import SwiftUI

struct ContentView: View {
    /// The description of the ring of wedges.
    @EnvironmentObject var ring: Ring

    var body: some View {
        // Create the button group.

        let overlayContent = VStack(alignment: .leading) {
            Button(action: newWedge) { Text("New Wedge") }
            Button(action: clear) { Text("Clear") }
            Spacer()
            Toggle(isOn: $ring.randomWalk) { Text("Randomize!") }
        }
        .padding()

        // Map over the array of wedge descriptions to produce the
        // wedge views, overlaying them via a ZStack.

        let wedges = ZStack {
            ForEach(ring.wedgeIDs, id: \.self) { wedgeID in
                WedgeView(wedge: self.ring.wedges[wedgeID]!)

                // use a custom transition for insertions and deletions.
                .transition(.scaleAndFade)

                // remove wedges when they're tapped.
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.ring.removeWedge(id: wedgeID)
                    }
                }
            }

            // Stop the window shrinking to zero when wedgeIDs.isEmpty.
            Spacer()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .padding()

        // Wrap the wedge container in a drawing group so that
        // everything draws into a single CALayer using Metal. The
        // CALayer contents are rendered by the app, removing the
        // rendering work from the shared render server.

        let drawnWedges = wedges.drawingGroup()

        // Composite the ring of wedges under the buttons, over a white
        // background.

        return drawnWedges
            .overlay(overlayContent, alignment: .topLeading)
    }

    // Button actions.

    func newWedge() {
        withAnimation(.spring()) {
            self.ring.addWedge(.random)
        }
    }

    func clear() {
        withAnimation(.easeInOut(duration: 1.0)) {
            self.ring.reset()
        }
    }
}

/// The custom view modifier defining the transition applied to each
/// wedge view as it's inserted and removed from the display.
struct ScaleAndFade: ViewModifier {
    /// True when the transition is active.
    var isEnabled: Bool

    // Scale and fade the content view while transitioning in and
    // out of the container.

    func body(content: Content) -> some View {
        return content
            .scaleEffect(isEnabled ? 0.1 : 1)
            .opacity(isEnabled ? 0 : 1)
    }
}

extension AnyTransition {
    static let scaleAndFade = AnyTransition.modifier(
        active: ScaleAndFade(isEnabled: true),
        identity: ScaleAndFade(isEnabled: false))
}
