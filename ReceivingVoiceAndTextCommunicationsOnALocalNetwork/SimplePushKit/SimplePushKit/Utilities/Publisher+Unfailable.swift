/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A publisher that catches upstream failures and converts a failable stream into a non-failable stream by producing a `Result`.
*/

import Foundation
import Combine

extension Publisher where Failure: Error {
    public func unfailable() -> AnyPublisher<Result<Output, Failure>, Never> {
        map { output -> Result<Output, Failure> in
            .success(output)
        }
        .catch { error -> Just<Result<Output, Failure>> in
            Just(.failure(error))
        }
        .eraseToAnyPublisher()
    }
}
