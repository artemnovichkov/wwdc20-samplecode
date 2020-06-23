/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A publisher that maps upstream nil values into non-nil values to downstream subscribers.
*/

import Foundation
import Combine

extension Publisher {
    public func dropNil<T>() -> AnyPublisher<T, Failure> where Output == T? {
        compactMap { $0 }
        .eraseToAnyPublisher()
    }
}
