/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model
*/

import UIKit

struct RBViewModel: Hashable {
    
    var coffee: Coffee
    var status: Status
    var isFavorite: Bool
    var locationsAvailable: [String]
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    init(coffee: Coffee, status: Status, locationsAvailable: [String]) {
        self.coffee = coffee
        self.status = status
        self.isFavorite = false
        self.locationsAvailable = locationsAvailable
    }
    
    static func == (lhs: RBViewModel, rhs: RBViewModel) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.status.rating == rhs.status.rating
    }
    
}

struct SampleData {
    static let coffees: [Coffee] = [
        Coffee(
            brand: "Eric's Java",
            caption: "Perfect for fertilizers",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .light,
            price: "$4.99",
            tastingNotes: [.bright, .nutty]),
        Coffee(
            brand: "Nathan's Espresso",
            caption: "Roasted in March",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .dark,
            price: "$14.99",
            tastingNotes: [.earthy, .smooth]),
        Coffee(
            brand: "Leilani's Latte",
            caption: "One of a kind",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .medium,
            price: "$12.99",
            tastingNotes: [.sweet]),
        Coffee(
            brand: "Greg's Cold Brew",
            caption: "Brewed for 48 hours",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .dark,
            price: "$18.99",
            tastingNotes: [.chocolatey, .bitter]),
        Coffee(
            brand: "Patti's Hazelnut",
            caption: "Crisp and sweet",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .medium,
            price: "$9.99",
            tastingNotes: [.chocolatey, .earthy, .smooth]),
        Coffee(
            brand: "Linden's Soul",
            caption: "Expertly crafted",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .medium,
            price: "$19.99",
            tastingNotes: [.chocolatey, .bright, .smooth]),
        Coffee(
            brand: "Night Cap",
            caption: "A night owls preference",
            image: #imageLiteral(resourceName: "coffee"),
            roast: .light,
            price: "$15.99",
            tastingNotes: [.earthy, .nutty])
    ]

    static let statuses: [Status] = [
        .unpurchased,
        .purchased(rating: .veryNotGood),
        .purchased(rating: .good),
        .purchased(rating: .notGood),
        .purchased(rating: .veryGood),
        .unpurchased,
        .purchased(rating: .moderate),
        .purchased(rating: .veryNotGood)
    ]

    static let locationsAvailable: [String] = [
        "Chris's Roastery",
        "Cafe Macs",
        "Bhavya's Bistro"
    ]

    static func viewModels() -> [RBViewModel] {
        return zip(coffees, statuses).map { coffee, status -> RBViewModel in
            return RBViewModel(coffee: coffee, status: status, locationsAvailable: locationsAvailable)
        }
    }
}
