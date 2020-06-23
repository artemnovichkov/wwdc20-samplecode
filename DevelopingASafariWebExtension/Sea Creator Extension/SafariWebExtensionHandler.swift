/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Communicates with the extension running in Safari.
*/
import SafariServices

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

	func beginRequest(with context: NSExtensionContext) {
        // Unpack the message from Safari Web Extension.
        let item = context.inputItems[0] as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey]

        // Update the value in UserDefaults.
        let defaults = UserDefaults(suiteName: "com.example.apple-samplecode.Sea-Creator.group")
        let messageDictionary = message as? [String: String]
        if messageDictionary?["message"] == "Word replaced" {
            var currentValue = defaults?.integer(forKey: "WordReplacementCount") ?? 0
            currentValue += 1
            defaults?.set(currentValue, forKey: "WordReplacementCount")
        }

        let response = NSExtensionItem()
        response.userInfo = [ SFExtensionMessageKey: [ "Response to": message ] ]
        
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
    
}
