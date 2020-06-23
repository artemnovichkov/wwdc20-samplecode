/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An ingredient with a measurement that informs its nutrition facts
*/

import SwiftUI
import NutritionFacts

struct MeasuredIngredient: Identifiable, Codable {
    var ingredient: Ingredient
    var measurement: Measurement<UnitVolume>

    init(_ ingredient: Ingredient, measurement: Measurement<UnitVolume>) {
        self.ingredient = ingredient
        self.measurement = measurement
    }

    // Identifiable
    var id: Ingredient.ID { ingredient.id }
}

extension MeasuredIngredient {
    var kilocalories: Int {
        guard let nutritionFact = nutritionFact else {
            return 0
        }
        return Int(nutritionFact.kilocalories)
    }

    // Nutritional information according to the quantity of this measurement.
    var nutritionFact: NutritionFact? {
        guard let nutritionFact = ingredient.nutritionFact else {
            return nil
        }
        let mass = measurement.convertedToMass(usingDensity: nutritionFact.density)
        return nutritionFact.converted(toMass: mass)
    }
}
