/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Displays progress towards the next free smoothie, as well as offers a way for users to create an account.
*/

import SwiftUI

struct RewardsView: View {
    @EnvironmentObject private var model: FrutaModel
    
    var blurView: some View {
        #if os(iOS)
        return VisualEffectBlur(blurStyle: .systemThinMaterial)
        #else
        return VisualEffectBlur()
        #endif
    }
    
    var signUpButton: some View {
        SignInWithAppleButton(.signUp, onRequest: { _ in }, onCompletion: model.authorizeUser)
            .frame(minWidth: 100, maxWidth: 400)
            .padding(.horizontal, 20)
    }
    
    var body: some View {
        ZStack {
            RewardsCard(
                totalStamps: model.account?.unspentPoints ?? 0,
                animatedStamps: model.account?.unstampedPoints ?? 0,
                hasAccount: model.hasAccount
            )
            .onDisappear {
                model.clearUnstampedPoints()
            }
            
            if !model.hasAccount {
                Group {
                    #if os(iOS)
                    signUpButton.frame(height: 45)
                    #else
                    signUpButton.frame(minWidth: 100, maxWidth: 400)
                    #endif
                }
                .padding(.horizontal, 20)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    blurView.edgesIgnoringSafeArea(.all)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BubbleBackground())
    }
}

struct SmoothieRewards_Previews: PreviewProvider {
    static let dataStore: FrutaModel = {
        var dataStore = FrutaModel()
        dataStore.createAccount()
        dataStore.orderSmoothie(.thatsBerryBananas)
        dataStore.orderSmoothie(.thatsBerryBananas)
        dataStore.orderSmoothie(.thatsBerryBananas)
        dataStore.orderSmoothie(.thatsBerryBananas)
        return dataStore
    }()
    
    static var previews: some View {
        Group {
            RewardsView()
                .preferredColorScheme(.light)
            RewardsView()
                .preferredColorScheme(.dark)
            RewardsView()
                .environmentObject(FrutaModel())
        }
        .environmentObject(dataStore)
    }
}
