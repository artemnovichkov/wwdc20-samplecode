/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension of Decodable for a type that can decode itself from JSON.
*/

import Foundation

extension Decodable {
    init?(decoder: JSONDecoder, data: Data) {
        do {
            self = try decoder.decode(Self.self, from: data)
        } catch {
            return nil
        }
    }
}
