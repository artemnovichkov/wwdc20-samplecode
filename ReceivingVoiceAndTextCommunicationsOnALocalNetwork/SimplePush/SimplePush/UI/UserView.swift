/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view presented when selecting a user in the DirectoryView or when receiving a call.
*/

import SwiftUI
import Combine

struct UserView: View {
    @ObservedObject var viewModel: UserViewModel
    var presenter: Presenter?
    
    var body: some View {
        ZStack {
            Button(action: {
                presenter?.dismiss()
            }, label: {
                Text("Done")
                .fontWeight(.medium)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            VStack(spacing: 0) {
                VStack(spacing: 7) {
                    Text("Contact")
                        .foregroundColor(Color("Colors/SecondaryText"))
                        .font(.subheadline)
                    Text(self.viewModel.user.deviceName)
                        .foregroundColor(Color("Colors/PrimaryText"))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                VStack {
                    contentView(height: 75)
                        .padding(.bottom, 15)
                    Text(viewModel.helpText)
                        .foregroundColor(Color("Colors/PrimaryText"))
                        .font(.subheadline)
                }
                Button(action: {
                    viewModel.presentedView = .messaging(viewModel.user, nil)
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 30.0))
                }
                .disabled(viewModel.disableCallActions)
                .padding(.bottom, 50.0)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .padding(20)
        .sheet(item: $viewModel.presentedView) { presentedView in
            view(for: presentedView)
        }
    }
    
    func contentView(height: CGFloat) -> some View {
        Button(action: {
            self.viewModel.phoneButtonDidPress()
        }) {
            Circle()
                .fill(callButtonColor(for: viewModel.callState))
            .overlay(
                Image(systemName: "phone.down")
                    .font(.system(size: height / 2, weight: .medium))
                    .foregroundColor(.white)
                    .offset(x: 0.0, y: -1)
                    .rotationEffect(callButtonRotationAngle(for: viewModel.callState))
                    .animation(.spring(response: 0.5, dampingFraction: 0.35, blendDuration: 0.0))
            )
            .frame(width: height, height: height)
        }
        .disabled(viewModel.disableCallActions)
    }
    
    @ViewBuilder func view(for presentedView: UserViewModel.PresentedView) -> some View {
        switch presentedView {
        case .messaging(let user, let message):
            let messagingViewModel = MessagingViewModel(receiver: user, message: message)
            MessagingView(viewModel: messagingViewModel, presenter: viewModel)
        }
    }
    
    func callButtonRotationAngle(for state: CallManager.State) -> Angle {
        switch state {
        case .connected, .connecting:
            return .degrees(0.0)
        case .disconnecting, .disconnected:
            return .degrees(-135)
        }
    }
    
    func callButtonColor(for state: CallManager.State) -> Color {
        guard !viewModel.disableCallActions else {
            return .gray
        }
        
        switch state {
        case .disconnecting(let reason) where reason != .hungUp:
            return .blue
        case .connecting, .connected, .disconnecting:
            return .red
        default:
            return .blue
        }
    }
}
