/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the recipe for a smoothie.
*/

import SwiftUI
import NutritionFacts

struct RecipeView: View {
    var smoothie: Smoothie
    
    @State private var smoothieCount = 1
    
    var backgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return Color(.textBackgroundColor)
        #endif
    }
    
    let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
    
    var pluralizer: String { smoothieCount == 1 ? "" : "s" }

    var recipeToolbar: some View {
        StepperView(
            value: $smoothieCount,
            label: "\(smoothieCount) Smoothie\(pluralizer)" ,
            configuration: StepperView.Configuration(increment: 1, minValue: 1, maxValue: 9)
        )
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                smoothie.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(recipeToolbar, alignment: .bottom)
                    
                VStack(alignment: .leading) {
                    Text("Ingredients")
                        .font(Font.title).bold()
                        .foregroundColor(.secondary)
                    
                    VStack {
                        ForEach(0 ..< smoothie.measuredIngredients.count) { index in
                            RecipeIngredientRow(measuredIngredient: smoothie.measuredIngredients[index], smoothieCount: smoothieCount)
                                .padding(.horizontal)
                            if index < smoothie.measuredIngredients.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical)
                    .background(Rectangle().fill(BackgroundStyle()))
                    .clipShape(shape)
                    .overlay(
                        shape
                            .inset(by: 0.5)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding()
            .frame(minWidth: 200, idealWidth: 400, maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationTitle(smoothie.title)
    }
}

struct RecipeIngredientRow: View {
    var measuredIngredient: MeasuredIngredient
    var smoothieCount: Int
    
    @State private var checked = false
    
    var ingredient: Ingredient {
        measuredIngredient.ingredient
    }
    
    var measurement: Measurement<UnitVolume> {
        measuredIngredient.measurement * Double(smoothieCount)
    }
    
    var body: some View {
        Button(action: { checked.toggle() }) {
            HStack {
                ingredient.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(ingredient.thumbnailCrop.scale * 1.25)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name).font(.headline)
                    MeasurementView(measurement: measurement)
                }

                Spacer()

                Toggle("Complete", isOn: $checked)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .toggleStyle(CircleToggleStyle())
    }
}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeView(smoothie: .thatsBerryBananas)
    }
}
