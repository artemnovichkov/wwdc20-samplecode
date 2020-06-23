/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A structure that represents a single drink consumed by the user.
*/

import Foundation

// The record of a single drink.
struct Drink: Hashable, Codable {
    
    // The amount of caffeine in the drink.
    let mgCaffeine: Double
    
    // The date when the drink was consumed.
    let date: Date
    
    // A globally unique identifier for the drink.
    let uuid: UUID
    
    // The drink initializer.
    init(mgCaffeine: Double, onDate date: Date, uuid: UUID = UUID()) {
        self.mgCaffeine = mgCaffeine
        self.date = date
        self.uuid = uuid
    }
    
    // Calculate the amount of caffeine remaining at the provided time,
    // based on a 5-hour half life.
    public func caffeineRemaining(at targetDate: Date) -> Double {
        // calculate the number of half-life time periods (5-hour increments)
        let intervals = targetDate.timeIntervalSince(date) / (60.0 * 60.0 * 5.0)
        return mgCaffeine * pow(0.5, intervals)
    }
}
