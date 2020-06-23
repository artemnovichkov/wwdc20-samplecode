/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A representation of a customer's account. Used for calculating free smoothie redemption.
*/

struct Account {
    var orderHistory = [Order]()
    var pointsSpent = 0
    var unstampedPoints = 0
    
    var pointsEarned: Int {
        orderHistory.map({ $0.points }).reduce(0, +)
    }
    
    var unspentPoints: Int {
        pointsEarned - pointsSpent
    }
    
    var canRedeemFreeSmoothie: Bool {
        unspentPoints >= 10
    }
    
    mutating func clearUnstampedPoints() {
        unstampedPoints = 0
    }
    
    mutating func appendOrder(_ order: Order) {
        orderHistory.append(order)
        unstampedPoints += order.points
    }
}
