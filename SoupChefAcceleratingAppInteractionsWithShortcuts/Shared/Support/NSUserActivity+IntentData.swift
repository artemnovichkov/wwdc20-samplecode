/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience utility for working with NSUserActivity.
*/

import Foundation
import MobileCoreServices

#if canImport(CoreSpotlight)
    import CoreSpotlight
    import UIKit
#endif

extension NSUserActivity {
    
    public enum ActivityKeys: String {
        case orderID
    }
    
    public static let viewMenuActivityType = "com.example.apple-samplecode.SoupChef.viewMenu"
    public static let orderCompleteActivityType = "com.example.apple-samplecode.SoupChef.orderComplete"
    
    public static var viewMenuActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: NSUserActivity.viewMenuActivityType)
        
        // User activites should be as rich as possible, with icons and localized strings for appropiate content attributes.
        userActivity.title = NSLocalizedString("ORDER_LUNCH_TITLE", comment: "View menu activity title")
        userActivity.isEligibleForPrediction = true
        
    #if canImport(CoreSpotlight)
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
        
        attributes.thumbnailData = #imageLiteral(resourceName: "tomato").pngData() // Used as an icon in Search.
        attributes.keywords = ["Order", "Soup", "Menu"]
        attributes.displayName = NSLocalizedString("ORDER_LUNCH_TITLE", comment: "View menu activity title")
        
        let localizationComment = "View menu content description"
        attributes.contentDescription = NSLocalizedString("VIEW_MENU_CONTENT_DESCRIPTION", comment: localizationComment)
        
        userActivity.contentAttributeSet = attributes
    #endif
        
        let phrase = NSString.deferredLocalizedIntentsString(with: "ORDER_LUNCH_SUGGESTED_PHRASE") as String
        userActivity.suggestedInvocationPhrase = phrase
        return userActivity
    }

}
