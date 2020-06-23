/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button for redeeming free smoothies.
*/

import SwiftUI

struct RedeemSmoothieButton: View {
    var action: () -> Void
    var height: CGFloat {
        #if os(macOS)
        return 30
        #else
        return 45
        #endif
    }
    
    var body: some View {
        Button(action: action) {
            Text("Redeem Free Smoothie!")
                .font(Font.headline.bold())
                .frame(height: height)
                .frame(minWidth: 100, maxWidth: 400)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(SquishableButtonStyle())
    }
}

struct RedeemSmoothieButton_Previews: PreviewProvider {
    static var previews: some View {
        RedeemSmoothieButton(action: {})
            .frame(width: 300)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
