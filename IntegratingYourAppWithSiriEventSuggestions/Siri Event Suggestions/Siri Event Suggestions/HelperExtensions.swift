/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A set of extensions to help make the rest of the sample code more succinct.
*/
import Foundation
import UIKit

extension UITableViewController {
    // For macOS we'll use UINavigationController instead of custom dismiss buttons for demo simplicity.
    open override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil) {
        #if targetEnvironment(macCatalyst)
        navigationController?.pushViewController(viewControllerToPresent, animated: true)
        #else
        super.present(viewControllerToPresent, animated: flag, completion: completion)
        #endif
    }
}

extension Calendar {
    public func components(inTimeZone timeZone: TimeZone,
                           byAdding components: DateComponents,
                           to date: Date,
                           wrappingComponents: Bool = false) -> DateComponents? {
        guard let newDate = self.date(byAdding: components, to: date, wrappingComponents: wrappingComponents) else {
            return nil
        }

        return self.dateComponents(in: timeZone, from: newDate)
    }

    public func components(inTimeZone timeZone: TimeZone,
                           byAdding components: DateComponents,
                           to otherComponents: DateComponents,
                           wrappingComponents: Bool = false) -> DateComponents? {
        guard let date = self.date(from: otherComponents) else {
            return nil
        }

        return self.components(inTimeZone: timeZone, byAdding: components, to: date, wrappingComponents: wrappingComponents)
    }
}

extension DateComponents {
    static func dateComponentsForTomorrow(withCalendar calendar: Calendar) -> DateComponents {
        let todayDateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        let tomorrowDateComponents = calendar.components(inTimeZone: calendar.timeZone,
                                                         byAdding: DateComponents(day: 1),
                                                         to: todayDateComponents,
                                                         wrappingComponents: false)!

        return tomorrowDateComponents
    }
}
