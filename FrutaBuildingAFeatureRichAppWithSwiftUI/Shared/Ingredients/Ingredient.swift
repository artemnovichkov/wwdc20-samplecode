/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that represents a smoothie ingredient and its appearance as a thumbnail and card.
*/

// MARK: - Ingredient

struct Ingredient: Identifiable, Codable {
    var id: String
    var name: String
    var title = CardTitle()
    var thumbnailCrop = Crop()
    var cardCrop = Crop()

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

// MARK: - All Ingredients

extension Ingredient {
    static let all: [Ingredient] = [
        .avocado,
        .almondMilk,
        .banana,
        .blueberry,
        .carrot,
        .chocolate,
        .coconut,
        .kiwi,
        .lemon,
        .mango,
        .orange,
        .papaya,
        .peanutButter,
        .pineapple,
        .raspberry,
        .spinach,
        .strawberry,
        .watermelon
    ]
    
    init?(for id: Ingredient.ID) {
        guard let result = Ingredient.all.first(where: { $0.id == id }) else {
            return nil
        }
        self = result
    }
}
