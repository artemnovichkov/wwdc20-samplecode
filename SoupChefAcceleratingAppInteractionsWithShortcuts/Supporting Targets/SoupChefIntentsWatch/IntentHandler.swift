/*
See LICENSE folder for this sample’s licensing information.

Abstract:
IntentHandler for watchOS
*/

import Intents
import SoupKitWatch

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        guard intent is OrderSoupIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }
        return OrderSoupIntentHandler()
    }
}
