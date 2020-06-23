/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A singleton class that keeps track of the current object handling requests from a `ShowDirectionsIntent`.
*/

import UIKit
import Intents

class AppIntentHandler {
    
    static var shared = AppIntentHandler()
    
    weak var currentIntentHandler: ShowDirectionsIntentHandling?
    
}
