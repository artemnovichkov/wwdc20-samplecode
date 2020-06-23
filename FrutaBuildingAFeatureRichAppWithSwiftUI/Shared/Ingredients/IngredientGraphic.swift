/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A graphic that displays an Ingredient as a thumbnail, a card highlighting its image, or the back of a card highlighting its nutrition facts.
*/

import SwiftUI
import NutritionFacts

struct IngredientGraphic: View {
    var ingredient: Ingredient
    var style: Style
    var closeAction: () -> Void = {}
    var flipAction: () -> Void = {}
    
    enum Style {
        case cardFront
        case cardBack
        case thumbnail
    }
    
    var displayingAsCard: Bool {
        style == .cardFront || style == .cardBack
    }
    
    var shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    
    var body: some View {
        ZStack {
            image
            if style != .cardBack {
                title
            }
            
            if style == .cardFront {
                cardControls(for: .front)
                    .foregroundColor(ingredient.title.color)
                    .opacity(ingredient.title.opacity)
                    .blendMode(ingredient.title.blendMode)
            }
            
            if style == .cardBack {
                #if os(iOS)
                VisualEffectBlur(blurStyle: .systemThinMaterial, vibrancyStyle: .fill) {
                    if let nutritionFact = ingredient.nutritionFact {
                        NutritionFactView(nutritionFact: nutritionFact)
                            .padding(.bottom, 70)
                    }
                    cardControls(for: .back)
                }
                #else
                VisualEffectBlur()
                if let nutritionFact = ingredient.nutritionFact {
                    NutritionFactView(nutritionFact: nutritionFact)
                        .padding(.bottom, 70)
                }
                cardControls(for: .back)
                #endif
            }
        }
        .frame(minWidth: 130, maxWidth: 400, maxHeight: 500)
        .clipShape(shape)
        .overlay(
            shape
                .inset(by: 0.5)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .contentShape(shape)
        .accessibilityElement(children: .contain)
    }
    
    var image: some View {
        GeometryReader { geo in
            ingredient.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(displayingAsCard ? ingredient.cardCrop.scale : ingredient.thumbnailCrop.scale)
                .offset(displayingAsCard ? ingredient.cardCrop.offset : ingredient.thumbnailCrop.offset)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(x: style == .cardBack ? -1 : 1)
        }
        .accessibility(hidden: true)
    }
    
    var title: some View {
        Text(ingredient.name.uppercased())
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lineLimit(1)
            .foregroundColor(ingredient.title.color)
            .rotationEffect(displayingAsCard ? ingredient.title.rotation: .degrees(0))
            .opacity(ingredient.title.opacity)
            .blendMode(ingredient.title.blendMode)
            .animatableFont(size: displayingAsCard ? ingredient.title.fontSize : 40, weight: .bold)
            .minimumScaleFactor(0.25)
            .offset(displayingAsCard ? ingredient.title.offset : .zero)
    }
    
    func cardControls(for side: FlipViewSide) -> some View {
        VStack {
            if side == .front {
                CardActionButton(label: "Close", systemImage: "xmark.circle.fill", action: closeAction)
                    .scaleEffect(displayingAsCard ? 1 : 0.5)
                    .opacity(displayingAsCard ? 1 : 0)
            }
            Spacer()
            CardActionButton(
                label: side == .front ? "Open Nutrition Facts" : "Close Nutrition Facts",
                systemImage: side == .front ? "info.circle.fill" : "arrow.left.circle.fill",
                action: flipAction
            )
            .scaleEffect(displayingAsCard ? 1 : 0.5)
            .opacity(displayingAsCard ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Previews

struct IngredientGraphic_Previews: PreviewProvider {
    static let ingredient = Ingredient.orange
    static var previews: some View {
        Group {
            IngredientGraphic(ingredient: ingredient, style: .thumbnail)
                .frame(width: 180, height: 180)
                .previewDisplayName("Thumbnail")
            
            IngredientGraphic(ingredient: ingredient, style: .cardFront)
                .aspectRatio(0.75, contentMode: .fit)
                .frame(width: 500, height: 600)
                .previewDisplayName("Card Front")

            IngredientGraphic(ingredient: ingredient, style: .cardBack)
                .aspectRatio(0.75, contentMode: .fit)
                .frame(width: 500, height: 600)
                .previewDisplayName("Card Back")
        }
        .previewLayout(.sizeThatFits)
    }
}
