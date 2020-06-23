/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The smoothie detail view that offers the smoothie for sale and lists its ingredients.
*/

import SwiftUI
import NutritionFacts

#if APPCLIP
import StoreKit
#endif

struct SmoothieView: View {
    var smoothie: Smoothie
    
    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: FrutaModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedIngredientID: Ingredient.ID?
    @State private var topmostIngredientID: Ingredient.ID?
    @Namespace private var namespace
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif
    
    var isFavorite: Bool {
        model.favoriteSmoothieIDs.contains(smoothie.id)
    }
    
    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                if let account = model.account, account.canRedeemFreeSmoothie {
                    RedeemSmoothieButton(action: redeemSmoothie)
                } else {
                    PaymentButton(action: orderSmoothie)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
        }
        .background(VisualEffectBlur().edgesIgnoringSafeArea(.all))
    }
    
    var body: some View {
        Group {
            #if APPCLIP
            container
                .appStoreOverlay(isPresented: $presentingAppStoreOverlay) {
                    SKOverlay.AppClipConfiguration(position: .bottom)
                }
            #elseif os(iOS)
            container
            #else
            container
                .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            #endif
        }
        .background(Rectangle().fill(BackgroundStyle()).edgesIgnoringSafeArea(.all))
        .navigationTitle(smoothie.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { model.toggleFavorite(smoothie: smoothie) }) {
                    Label("Favorite", systemImage: isFavorite ? "heart.fill" : "heart")
                        .labelStyle(IconOnlyLabelStyle())
                }
                .accessibility(label: Text("\(isFavorite ? "Remove from" : "Add to") Favorites"))
            }
        }
        .sheet(isPresented: $presentingOrderPlacedSheet) {
            VStack(spacing: 0) {
                #if APPCLIP
                OrderPlacedView(presentingAppStoreOverlay: $presentingAppStoreOverlay)
                #else
                OrderPlacedView()
                #endif
                
                #if os(macOS)
                Divider()
                HStack {
                    Spacer()
                    Button(action: { presentingOrderPlacedSheet = false }) {
                        Text("Done")
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
                .background(VisualEffectBlur())
                #endif
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { presentingOrderPlacedSheet = false }) {
                        Text("Done")
                    }
                }
            }
            .environmentObject(model)
        }
        .alert(isPresented: $presentingSecurityAlert) {
            Alert(
                title: Text("Payments Disabled"),
                message: Text("The Fruta QR code was scanned too far from the shop, payments are disabled for your protection."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    var container: some View {
        ZStack {
            ScrollView {
                #if os(iOS)
                content
                #else
                content
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                #endif
            }
            .overlay(bottomBar, alignment: .bottom)
            .accessibility(hidden: selectedIngredientID != nil)

            VisualEffectBlur()
                .edgesIgnoringSafeArea(.all)
                .opacity(selectedIngredientID != nil ? 1 : 0)
            
            ForEach(smoothie.menuIngredients) { measuredIngredient in
                let presenting = selectedIngredientID == measuredIngredient.id
                IngredientCard(ingredient: measuredIngredient.ingredient, presenting: presenting, closeAction: deselectIngredient)
                    .matchedGeometryEffect(id: measuredIngredient.id, in: namespace, isSource: presenting)
                    .aspectRatio(0.75, contentMode: .fit)
                    .shadow(color: Color.black.opacity(presenting ? 0.2 : 0), radius: 20, y: 10)
                    .padding(20)
                    .opacity(presenting ? 1 : 0)
                    .zIndex(topmostIngredientID == measuredIngredient.id ? 1 : 0)
                    .accessibilityElement(children: .contain)
                    .accessibility(sortPriority: presenting ? 1 : 0)
                    .accessibility(hidden: !presenting)
            }
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            SmoothieHeaderView(smoothie: smoothie)
                
            VStack(alignment: .leading) {
                Text("Ingredients")
                    .font(Font.title).bold()
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .top)], alignment: .center, spacing: 16) {
                    ForEach(smoothie.menuIngredients) { measuredIngredient in
                        let ingredient = measuredIngredient.ingredient
                        let presenting = selectedIngredientID == measuredIngredient.id
                        Button(action: { select(ingredient: ingredient) }) {
                            IngredientGraphic(ingredient: measuredIngredient.ingredient, style: presenting ? .cardFront : .thumbnail)
                                .matchedGeometryEffect(
                                    id: measuredIngredient.id,
                                    in: namespace,
                                    isSource: !presenting
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(SquishableButtonStyle(fadeOnPress: false))
                        .aspectRatio(1, contentMode: .fit)
                        .zIndex(topmostIngredientID == measuredIngredient.id ? 1 : 0)
                        .accessibility(label: Text("\(ingredient.name) Ingredient"))
                    }
                }
            }
            .padding()
        }
        .padding(.bottom, 90)
    }
    
    func orderSmoothie() {
        guard model.applePayAllowed else {
            presentingSecurityAlert = true
            return
        }
        model.orderSmoothie(smoothie)
        presentingOrderPlacedSheet = true
    }
    
    func redeemSmoothie() {
        model.redeemSmoothie(smoothie)
        presentingOrderPlacedSheet = true
    }
    
    func select(ingredient: Ingredient) {
        topmostIngredientID = ingredient.id
        withAnimation(.openCard) {
            selectedIngredientID = ingredient.id
        }
    }
    
    func deselectIngredient() {
        withAnimation(.closeCard) {
            selectedIngredientID = nil
        }
    }
}

struct SmoothieView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SmoothieView(smoothie: .berryBlue)
            }
            
            ForEach([Smoothie.thatsBerryBananas, .oneInAMelon, .berryBlue]) { smoothie in
                SmoothieView(smoothie: smoothie)
                    .previewLayout(.sizeThatFits)
                    .frame(height: 700)
            }
        }
        .environmentObject(FrutaModel())
    }
}
