/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This type encapsulates the attributes of a recipe.
*/

import Foundation
import Intents

extension Recipe: CaseIterable {
    
    public typealias AllCases = [Recipe]
    
    public static var allCases: [Recipe] {
        return [
            Recipe(name: "Spicy Tomato Sauce",
                   iconImageName: "spicy_tomato_sauce",
                   servings: "6 cups",
                   time: "1 hour 20 minutes",
                   ingredients: [
                    "2 large onions, finely chopped",
                    "10 cloves garlic, minced",
                    "1 28oz can of peeled tomatoes",
                    "1 1/2 cup basil, chopped",
                    "2 tsp red crushed peppers",
                    "3 springs fresh thyme leaves, pulled off stem",
                    "1/4 cup olive oil",
                    "salt / freshly ground black pepper",
                    "1 tsp sugar"
                   ],
                   directions: [
                    "In a large pot, heat olive oil on medium heat.",
                    "Add minced garlic and sauté for a few seconds until fragrant.",
                    "Add chopped onions and cook until translucent (be sure not to burn or over-cook).",
                    "Add crushed red peppers and thyme leaves and cook for about 30 more seconds.",
                    "Add tomatoes and adjust heat to maintain a gentle simmer and cook for 1 hour.",
                    "The sauce will reduce by about 1/2 or until it has a thick consistency.",
                    "Add in the chopped basil and sugar and simmer for another 30 minutes.",
                    "Season with salt and freshly ground black pepper to taste.",
                    "Once the sauce is reduced and reaches desired consistency, " +
                    "use immediately or cool and store in fridge or freezer. "
                   ]),
            Recipe(name: "Chickpea Curry",
                   iconImageName: "chickpea_curry",
                   servings: "3",
                   time: "25 minutes",
                   ingredients: [
                    "2 medium onions, diced",
                    "1 bell pepper, seeded and diced",
                    "2 carrots, diced",
                    "2 tbsp olive oil",
                    "3 cloves garlic, chopped",
                    "1/4 cup lime juice",
                    "1-2 tsp curry paste",
                    "1 can coconut milk (1 can = 1.5 cups)",
                    "1 can chickpeas, drained and rinsed",
                    "1-2 tbsp soy sauce",
                    "2-3 medium tomato",
                    "1 cup basil, fresh",
                    "1 tsp maple syrup",
                    "1 tsp cilantro"
                   ],
                   directions: [
                    "Add oil, carrots, bell peppers, and onions into a large pan and cook " +
                    "on a low-medium heat until onions start to soften and turn clear, about 5 minutes.",
                    "Add garlic and cook for 1 minute.",
                    "Add curry paste and coconut milk, stirring until curry is dissolved.",
                    "Add chickpeas and soy sauce, and cook on a medium heat for 5 minutes, " +
                    "bringing the curry to a boil. If it starts to burn, reduce heat immediately.",
                    "Add the chopped tomatoes, chopped basil, lime juice, soy sauce and gently simmer the curry for another 2 minutes.",
                    "If desired add a second tbsp soy sauce and the syrup or brown sugar. Give it another stir.",
                    "Garnish with cilantro and serve with lime wedges and rice."
                   ]
            ),
            Recipe(name: "Cinnamon Apple Cake",
                   iconImageName: "apple_cake",
                   servings: "8 slices",
                   time: "45 minutes",
                   ingredients: [
                    "1 2/3 cups flour",
                    "1/2 cup brown sugar",
                    "1 tsp baking powder",
                    "1 tsp cinnamon",
                    "1 tsp nutmeg",
                    "1 cup coconut milk",
                    "1/3 cup canola oil",
                    "1 1/2 tsp vanilla",
                    "1 tbsp apple cider vinegar",
                    "2 apples, peeled and thinly sliced",
                    "canola oil spray",
                    "powdered sugar",
                    "1/2 tsp cinnamon"
                   ],
                   directions: [
                    "Preheat oven to 360F.",
                    "In large bowl mix together all dry ingredients.",
                    "In a separate large bowl mix together all wet ingredients.",
                    "Using a hand mixer or whisk, add dry ingredients to the " +
                    "wet ingredients and mix together well until you get a smooth batter.",
                    "Line a baking tin with baking paper and then spray the sides with oil.",
                    "Pour batter into the cake tin and spread evenly.",
                    "Place the apple slices on the batter in a star shape.",
                    "Bake the cake in the preheated oven for 35 minutes.",
                    "Let cool, then sprinkle with powdered sugar and cinnamon."
                   ])
        ]
    }
    
    convenience init(name: String, iconImageName: String, servings: String, time: String, ingredients: [String], directions: [String]) {
        self.init(identifier: name, display: name, subtitle: nil, image: INImage(named: iconImageName))
        self.servings = servings
        self.time = time
        self.ingredients = ingredients
        self.directions = directions
        self.iconImageName = iconImageName
    }
    
}
