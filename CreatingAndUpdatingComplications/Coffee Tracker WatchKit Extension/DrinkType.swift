/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The valid drink types.
*/

import Foundation

// Define the types of drinks supported by Coffee Tracker.
enum DrinkType: Int, CaseIterable, Identifiable {
    
    case smallCoffee
    case mediumCoffee
    case largeCoffee
    case singleEspresso
    case doubleEspresso
    case quadEspresso
    case blackTea
    case greenTea
    case softDrink
    case energyDrink
    case chocolate
    
    // A unique ID for each drink.
    var id: Int {
        self.rawValue
    }
    
    // The name of the drink as a user readable string.
    var name: String {
        switch self {
        case .smallCoffee:
            return "Small Coffee"
        case .mediumCoffee:
            return "Medium Coffee"
        case .largeCoffee:
            return "Large Coffee"
        case .singleEspresso:
            return "Single Espresso"
        case .doubleEspresso:
            return "Double Espresso"
        case .quadEspresso:
            return "Quad Espresso"
        case .blackTea:
            return "Black Tea"
        case .greenTea:
            return "Green Tea"
        case .softDrink:
            return "Soft Drink"
        case .energyDrink:
            return "Energy Drink"
        case .chocolate:
            return "Chocolate"
        }
    }
    
    // The amount of caffeine in the drink.
    var mgCaffeinePerServing: Double {
        switch self {
        case .smallCoffee:
            return 96.0
        case .mediumCoffee:
            return 144.0
        case .largeCoffee:
            return 192.0
        case .singleEspresso:
            return 64.0
        case .doubleEspresso:
            return 128.0
        case .quadEspresso:
            return 256.0
        case .blackTea:
            return 47.0
        case .greenTea:
            return 28.0
        case .softDrink:
            return 22.0
        case .energyDrink:
            return 29.0
        case .chocolate:
            return 18.0
        }
    }
}
