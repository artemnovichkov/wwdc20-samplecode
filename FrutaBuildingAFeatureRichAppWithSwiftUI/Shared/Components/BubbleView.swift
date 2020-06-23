/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A graphical bubble-like view, used behind the RewardsCard.
*/

import SwiftUI

struct BubbleView: View {
    var size: CGFloat = 30
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    var opacity: Double = 0.1
    
    @State private var shimmer: Bool = .random()
    @State private var shimmerDelay: Double = .random(in: 0.15...0.55)
    
    @State private var float: Bool = .random()
    @State private var floatDelay: Double = .random(in: 0.15...0.55)
    
    var body: some View {
        Circle()
            .blendMode(.overlay)
            .opacity(shimmer ? opacity * 2 : opacity)
            .frame(width: size, height: size)
            .scaleEffect(shimmer ? 1.1 : 1)
            .offset(x: xOffset, y: yOffset)
            .offset(y: float ? 4 : 0)
            .onAppear {
                #if !os(macOS)
                withAnimation(Animation.easeInOut(duration: 4 - shimmerDelay).repeatForever().delay(shimmerDelay)) {
                    shimmer.toggle()
                }
                withAnimation(Animation.easeInOut(duration: 8 - floatDelay).repeatForever().delay(floatDelay)) {
                    float.toggle()
                }
                #endif
            }
    }
}

struct BubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ZStack {
                BubbleView(opacity: 0.9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .foregroundColor(.red)
            
            ZStack {
                BubbleView(opacity: 0.9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .foregroundColor(.blue)
            
            ZStack {
                BubbleView(size: 300, yOffset: -150)
                BubbleView(size: 260, xOffset: 40, yOffset: -60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            BubbleView(size: 100, xOffset: -40, yOffset: 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
