/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This struct encapsulates the configuration of the `UITableView` in `OrderDetailViewController`.
*/

import Foundation
import SoupKit

struct OrderDetailTableConfiguration {
    
    enum Purpose {
        case newOrder, historicalOrder
    }
    
    enum SectionType: String {
        case price = "Price"
        case quantity = "Quantity"
        case toppings = "Toppings"
        case total = "Total"
    }
    
    enum ReuseIdentifiers: String {
        case basic = "Basic Cell"
        case quantity = "Quantity Cell"
    }
    
    public let purpose: Purpose
    
    init(for purpose: Purpose) {
        self.purpose = purpose
    }
    
    typealias SectionModel = (type: SectionType, rowCount: Int, cellReuseIdentifier: String)
    
    private static let newOrderSectionModel: [SectionModel] = [SectionModel(type: .price,
                                                                            rowCount: 1,
                                                                            cellReuseIdentifier: ReuseIdentifiers.basic.rawValue),
                                                               SectionModel(type: .quantity,
                                                                            rowCount: 1,
                                                                            cellReuseIdentifier: ReuseIdentifiers.quantity.rawValue),
                                                               SectionModel(type: .toppings,
                                                                            rowCount: Order.MenuItemTopping.allCases.count,
                                                                            cellReuseIdentifier: ReuseIdentifiers.basic.rawValue),
                                                               SectionModel(type: .total,
                                                                            rowCount: 1,
                                                                            cellReuseIdentifier: ReuseIdentifiers.basic.rawValue)]
    
    private static let historicalOrderSectionModel: [SectionModel] = [SectionModel(type: .quantity,
                                                                                   rowCount: 1,
                                                                                   cellReuseIdentifier: ReuseIdentifiers.quantity.rawValue),
                                                                      SectionModel(type: .toppings,
                                                                                   rowCount: Order.MenuItemTopping.allCases.count,
                                                                                   cellReuseIdentifier: ReuseIdentifiers.basic.rawValue),
                                                                      SectionModel(type: .total,
                                                                                   rowCount: 1,
                                                                                   cellReuseIdentifier: ReuseIdentifiers.basic.rawValue)]
    
    var sections: [SectionModel] {
        switch purpose {
            case .newOrder: return OrderDetailTableConfiguration.newOrderSectionModel
            case .historicalOrder: return OrderDetailTableConfiguration.historicalOrderSectionModel
        }
    }
}
