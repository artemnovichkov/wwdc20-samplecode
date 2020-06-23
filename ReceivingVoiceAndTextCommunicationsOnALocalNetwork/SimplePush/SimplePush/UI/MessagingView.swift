/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view presented when sending or replying to a message.
*/

import Foundation
import SwiftUI
import SimplePushKit

struct MessagingView: View {
    @ObservedObject var viewModel: MessagingViewModel
    var presenter: Presenter?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: self.sectionHeader(message: viewModel.message)) {
                    TextField(self.viewModel.message == nil ? "Message" : "Reply", text: self.$viewModel.reply)
                        .keyboardType(.default)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .environment(\.defaultMinListRowHeight, 50.0)
            .navigationBarTitle(self.viewModel.message == nil ? "New Message" : "Reply", displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                presenter?.dismiss()
            }, label: {
                Text("Done")
                    .fontWeight(.medium)
            }), trailing: Button(action: {
                self.viewModel.sendMessage()
                presenter?.dismiss()
            }, label: {
                Text("Send")
                    .fontWeight(.medium)
            })
            .disabled(viewModel.textActionsAreDisabled)
            )
        }
    }
    
    @ViewBuilder func sectionHeader(message: TextMessage?) -> some View {
        if let message = message {
            MessageBubbleView(message: message)
                .padding([.top, .bottom], 20)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } else {
            EmptyView()
        }
    }
}
