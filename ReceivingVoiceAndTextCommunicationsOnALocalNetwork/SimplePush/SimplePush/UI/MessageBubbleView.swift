/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom view for presenting the received message inside of a `MessagingView`.
*/

import Foundation
import SwiftUI
import SimplePushKit

struct MessageBubbleView: View {
    var message: TextMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "message")
                Text(message.routing.sender.deviceName.uppercased())
            }
            .font(.caption)

            Text(message.message)
                .font(.body)
                .textCase(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(.white)
        .padding(15)
        .background(background)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.blue)
    }
}
