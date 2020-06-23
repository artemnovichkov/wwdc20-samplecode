/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The bubbly background for use behind the RewardsCard and Fruta widgets.
*/

import SwiftUI

struct BubbleBackground: View {
    var body: some View {
        ZStack {
            Color("bubbles-background")
            
            ZStack(alignment: .topTrailing) {
                BubbleView(size: 300, xOffset: 80, yOffset: -150, opacity: 0.05)
                BubbleView(size: 100, xOffset: 60, yOffset: 200, opacity: 0.1)
                BubbleView(size: 35, xOffset: -220, yOffset: 80, opacity: 0.15)
                BubbleView(size: 10, xOffset: -320, yOffset: 50, opacity: 0.1)
                BubbleView(size: 12, xOffset: -250, yOffset: 8, opacity: 0.1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            ZStack(alignment: .bottomLeading) {
                BubbleView(size: 320, xOffset: -190, yOffset: 150, opacity: 0.05)
                BubbleView(size: 60, xOffset: -40, yOffset: -210, opacity: 0.1)
                BubbleView(size: 10, xOffset: 320, yOffset: -50, opacity: 0.1)
                BubbleView(size: 12, xOffset: 250, yOffset: -20, opacity: 0.1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            LinearGradient(
                gradient: Gradient(colors: [Color.primary.opacity(0.25), Color.primary.opacity(0)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.overlay)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

struct RewardsBubbleBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BubbleBackground()
                .frame(width: 350, height: 700)
            
            BubbleBackground()
                .frame(width: 800, height: 400)
            
            BubbleBackground()
                .frame(width: 200, height: 200)
        }
    }
}
