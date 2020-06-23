/*
See LICENSE folder for this sample’s licensing information.

Abstract:
IntentHandler that vends instances of OrderSoupIntentHandler for iOS
*/

import Intents
import SoupKit

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        guard intent is OrderSoupIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }
        return OrderSoupIntentHandler()
    }
}

