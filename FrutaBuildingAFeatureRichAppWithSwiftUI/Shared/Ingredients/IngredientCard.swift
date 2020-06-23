/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A card that presents an IngredientGraphic and allows it to flip over to reveal its nutritional information
*/

import SwiftUI
import NutritionFacts

// MARK: - Ingredient View

struct IngredientCard: View {
    var ingredient: Ingredient
    var presenting: Bool
    var closeAction: () -> Void = {}
    
    @State private var visibleSide = FlipViewSide.front
    
    var body: some View {
        FlipView(visibleSide: visibleSide) {
            IngredientGraphic(ingredient: ingredient, style: presenting ? .cardFront : .thumbnail, closeAction: closeAction, flipAction: flipCard)
        } back: {
            IngredientGraphic(ingredient: ingredient, style: .cardBack, closeAction: closeAction, flipAction: flipCard)
        }
        .contentShape(Rectangle())
        .animation(.flipCard, value: visibleSide)
    }
    
    func flipCard() {
        visibleSide.toggle()
    }
}
