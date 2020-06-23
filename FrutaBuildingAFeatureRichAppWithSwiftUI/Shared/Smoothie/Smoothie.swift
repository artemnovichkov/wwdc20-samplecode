/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that represents a smoothie — including its descriptive information and ingredients (and nutrition facts).
*/

import Foundation
import NutritionFacts

struct Smoothie: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var measuredIngredients: [MeasuredIngredient]
    var hasFreeRecipe = false
}

extension Smoothie {
    init?(for id: Smoothie.ID) {
        guard let smoothie = Smoothie.all.first(where: { $0.id == id }) else { return nil }
        self = smoothie
    }

    var kilocalories: Int {
        let value = measuredIngredients.reduce(0) { total, ingredient in total + ingredient.kilocalories }
        return Int(round(Double(value) / 10.0) * 10)
    }

    // The nutritional information for the combined ingredients
    var nutritionFact: NutritionFact {
        let facts = measuredIngredients.compactMap { $0.nutritionFact }
        guard let firstFact = facts.first else {
            print("Could not find nutrition facts for \(title) — using `banana`'s nutrition facts.")
            return .banana
        }
        return facts.dropFirst().reduce(firstFact, +)
    }
    
    var menuIngredients: [MeasuredIngredient] {
        measuredIngredients.filter { $0.id != Ingredient.water.id }
    }
}

extension Smoothie: Hashable {
    static func == (lhs: Smoothie, rhs: Smoothie) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Smoothie List
extension Smoothie {
    static let all: [Smoothie] = [
        .berryBlue,
        .carrotChops,
        .hulkingLemonade,
        .pinaColada,
        .kiwiCutie,
        .lemonberry,
        .loveYouBerryMuch,
        .mangoJambo,
        .oneInAMelon,
        .peanutButterCup,
        .papasPapaya,
        .sailorMan,
        .thatsASmore,
        .thatsBerryBananas,
        .tropicalBlue
    ]
    
    static let allIDs: [Smoothie.ID] = all.map { $0.id }

    static let berryBlue = Smoothie(
        id: "berry-blue",
        title: "Berry Blue",
        description: "Filling and refreshing, this smoothie will fill you with joy!",
        measuredIngredients: [
            MeasuredIngredient(.orange, measurement: Measurement(value: 1.5, unit: .cups)),
            MeasuredIngredient(.blueberry, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.avocado, measurement: Measurement(value: 0.2, unit: .cups))
        ],
        hasFreeRecipe: true
    )
    
    static let carrotChops = Smoothie(
        id: "carrot-chops",
        title: "Carrot Chops",
        description: "Packed with vitamin A and C, Carrot Chops is a great way to start your day!",
        measuredIngredients: [
            MeasuredIngredient(.orange, measurement: Measurement(value: 1.5, unit: .cups)),
            MeasuredIngredient(.carrot, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.mango, measurement: Measurement(value: 0.5, unit: .cups))
        ],
        hasFreeRecipe: true
    )

    static let pinaColada = Smoothie(
        id: "if-you-like-pina-colada",
        title: "If You Like Piña Colada",
        description: "…and getting caught in the rain. This is the smoothie for you!",
        measuredIngredients: [
            MeasuredIngredient(.pineapple, measurement: Measurement(value: 1.5, unit: .cups)),
            MeasuredIngredient(.almondMilk, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.coconut, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let hulkingLemonade = Smoothie(
        id: "hulking-lemonade",
        title: "Hulking Lemonade",
        description: "This is not just any lemonade. It will give you powers you'll struggle to control!",
        measuredIngredients: [
            MeasuredIngredient(.lemon, measurement: Measurement(value: 1.5, unit: .cups)),
            MeasuredIngredient(.spinach, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.avocado, measurement: Measurement(value: 0.2, unit: .cups)),
            MeasuredIngredient(.water, measurement: Measurement(value: 0.2, unit: .cups))
        ]
    )
    
    static let kiwiCutie = Smoothie(
        id: "kiwi-cutie",
        title: "Kiwi Cutie",
        description: "Kiwi Cutie is beautiful inside and out! Packed with nutrients to start your day!",
        measuredIngredients: [
            MeasuredIngredient(.kiwi, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.orange, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.spinach, measurement: Measurement(value: 1, unit: .cups))
        ]
    )
    
    static let lemonberry = Smoothie(
        id: "lemonberry",
        title: "Lemonberry",
        description: "A refreshing blend that's a real kick!",
        measuredIngredients: [
            MeasuredIngredient(.raspberry, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.strawberry, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.lemon, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.water, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let loveYouBerryMuch = Smoothie(
        id: "love-you-berry-much",
        title: "Love You Berry Much",
        description: "If you love berries berry berry much, you will love this one!",
        measuredIngredients: [
            MeasuredIngredient(.strawberry, measurement: Measurement(value: 0.75, unit: .cups)),
            MeasuredIngredient(.blueberry, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.raspberry, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.water, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let mangoJambo = Smoothie(
        id: "mango-jambo",
        title: "Mango Jambo",
        description: "Dance around with this delicious tropical blend!",
        measuredIngredients: [
            MeasuredIngredient(.mango, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.pineapple, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.water, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let oneInAMelon = Smoothie(
        id: "one-in-a-melon",
        title: "One in a Melon",
        description: "Feel special this summer with the coolest drink in our menu!",
        measuredIngredients: [
            MeasuredIngredient(.watermelon, measurement: Measurement(value: 2, unit: .cups)),
            MeasuredIngredient(.raspberry, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.water, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let papasPapaya = Smoothie(
        id: "papas-papaya",
        title: "Papa's Papaya",
        description: "Papa would be proud of you if he saw you drinking this!",
        measuredIngredients: [
            MeasuredIngredient(.orange, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.mango, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.papaya, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
    
    static let peanutButterCup = Smoothie(
        id: "peanut-butter-cup",
        title: "Peanut Butter Cup",
        description: "Ever wondered what it was like to drink a peanut butter cup? Wonder no more!",
        measuredIngredients: [
            MeasuredIngredient(.almondMilk, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.banana, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.chocolate, measurement: Measurement(value: 2, unit: .tablespoons)),
            MeasuredIngredient(.peanutButter, measurement: Measurement(value: 1, unit: .tablespoons))
        ]
    )
    
    static let sailorMan = Smoothie(
        id: "sailor-man",
        title: "Sailor Man",
        description: "Get strong with this delicious spinach smoothie!",
        measuredIngredients: [
            MeasuredIngredient(.orange, measurement: Measurement(value: 1.5, unit: .cups)),
            MeasuredIngredient(.spinach, measurement: Measurement(value: 1, unit: .cups))
        ]
    )
    
    static let thatsASmore = Smoothie(
        id: "thats-a-smore",
        title: "That's a Smore!",
        description: "When the world seems to rock like you've had too much choc, that's a smore!",
        measuredIngredients: [
            MeasuredIngredient(.almondMilk, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.coconut, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.chocolate, measurement: Measurement(value: 1, unit: .tablespoons))
        ]
    )
    
    static let thatsBerryBananas = Smoothie(
        id: "thats-berry-bananas",
        title: "That's Berry Bananas!",
        description: "You'll go crazy with this classic!",
        measuredIngredients: [
            MeasuredIngredient(.almondMilk, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.banana, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.strawberry, measurement: Measurement(value: 1, unit: .cups))
        ],
        hasFreeRecipe: true
    )
    
    static let tropicalBlue = Smoothie(
        id: "tropical-blue",
        title: "Tropical Blue",
        description: "A delicious blend of tropical fruits and blueberries will have you sambaing around like you never knew you could!",
        measuredIngredients: [
            MeasuredIngredient(.almondMilk, measurement: Measurement(value: 1, unit: .cups)),
            MeasuredIngredient(.banana, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.blueberry, measurement: Measurement(value: 0.5, unit: .cups)),
            MeasuredIngredient(.mango, measurement: Measurement(value: 0.5, unit: .cups))
        ]
    )
}
