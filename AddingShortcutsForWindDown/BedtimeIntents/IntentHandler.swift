/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`IntentHandler` determines if the intent is supported by this app.
*/

import Intents

/// `IntentHandler` is the entry point to the Intent extension for a shortcut. It determines if the intent is supported by this extension.
class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        guard intent is INPlayMediaIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }

        return PlayMediaIntentHandler()
    }
}
