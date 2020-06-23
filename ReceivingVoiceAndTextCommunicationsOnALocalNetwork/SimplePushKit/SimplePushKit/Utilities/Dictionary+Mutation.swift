/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extention of `Dictionary` that checks for an existing key and creates and stores a new value if the key isn't present.
*/

import Foundation

extension Dictionary {
    public mutating func get(_ key: Key, insert newValue: @autoclosure () -> Value) -> Value {
        var value = self[key]
        
        if let value = self[key] {
            return value
        }
        
        value = newValue()
        self[key] = value!
        return value!
    }
}
