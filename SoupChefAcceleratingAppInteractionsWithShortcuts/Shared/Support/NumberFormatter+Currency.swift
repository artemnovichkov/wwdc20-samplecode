/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience utility to format numbers as currency
*/

import Foundation

extension NumberFormatter {
    public static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}
