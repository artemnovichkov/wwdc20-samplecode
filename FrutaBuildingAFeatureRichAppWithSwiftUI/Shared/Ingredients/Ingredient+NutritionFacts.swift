/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension that allows Ingredients to look up nutrition facts for a cup's worth of its volume.
*/

import NutritionFacts

extension Ingredient {
    var nutritionFact: NutritionFact? {
        NutritionFact.lookupFoodItem(id, forVolume: .cups(1))
    }
}
