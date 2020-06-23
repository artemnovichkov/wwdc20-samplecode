# Creating and Updating Complications

Build complications that display current information from your app.

## Overview

The Coffee Tracker app records a user's caffeine intake. 
Each time the user adds a drink, the app recalculates the current caffeine levels 
and the equivalent cups of coffee consumed. 
It then updates the complication timeline 
and estimates the decrease in the user's caffeine level over the next 24 hours.

This sample demonstrates the basic steps to set up and fill the complication's timeline, 
including setting up support for complications, 
creating entries to fill the complication's timeline, 
and then updating the timeline every time the user makes a change.

The app also updates the complications based on external changes 
that occur when the app isn't running. 
Coffee Tracker saves and reads caffeine samples to HealthKit, 
so the app must respond to any external changes, 
such as another app adding or deleting a caffeine sample from HealthKit. 
Coffee Tracker uses a background refresh task to query HealthKit for changes, 
and updates the app's data and the complication timeline.

## Configure the Sample Code Project

First, build and run the sample code project in the simulator:

1. Click the Digital Crown to exit the app and return to the watch face.
2. Using the trackpad, firmly press the watch face to put the face in edit mode, then tap Customize.
3. Swipe left until the configuration screen highlights the complications. Select the complication to modify.
4. Scroll to the Coffee Tracker complication, and then click the Digital Crown again to save your changes.
5. Tap the Coffee Tracker complication to go back to the app.

For more information on setting up watch faces, see [Change the watch face on your Apple Watch](https://support.apple.com/en-us/HT205536).

## Set Up Support for Complications

The app declares support for all complication families in the Complications Configuration 
section of the WatchKit Extension’s General tab. 
It also declares the `ComplicationController` class as the complication's data source. 
Xcode saves these settings in the WatchKit Extension's `Info.plist` file.

Next, the Coffee Tracker app implements the [`CLKComplicationDataSource`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource) protocol's 
methods to configure the app's timeline.
Because the app can easily calculate caffeine levels in the future,
the data source declares that it can batch-load future timeline entries.

First, it implements the 
[`getSupportedTimeTravelDirections(for:withHandler:)`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource/1628002-getsupportedtimetraveldirections) 
method, indicating that it can  provide future data.

``` swift
// Define whether the app can provide future data.
func getSupportedTimeTravelDirections(for complication: CLKComplication,
                                      withHandler handler:@escaping (CLKComplicationTimeTravelDirections) -> Void) {
    // Indicate that the app can provide future timeline entries.
    handler([.forward])
}
```

The app implements the [`getTimelineEndDate(for:withHandler:)`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource/1628056-gettimelineenddate) method 
and sets the end date for the timeline to 24 hours in the future. 
ClockKit can now request batches of timeline entries up to that deadline. 
After that point, the caffeine level drops to `0.0`. 
Because the data doesn't change after that point, 
ClockKit won't need any additional timeline entries until  the user adds another drink.

``` swift
// Define how far into the future the app can provide data.
func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
    // Indicate that the app can provide timeline entries for the next 24 hours.
    handler(Date().addingTimeInterval(24.0 * 60.0 * 60.0))
}
```

Finally, the app sets the privacy behavior by implementing the [`getPrivacyBehavior(for:withHandler:)`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource/1627965-getprivacybehavior) method, 
hiding the complication data on the user's caffeine intake when the watch is locked.

``` swift
// Define whether the complication is visible when the watch is unlocked.
func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
    // This is potentially sensitive data. Hide it on the lock screen.
    handler(.hideOnLockScreen)
}
```

## Display Current Data

Coffee Tracker uses three techniques to keep the complications up to date.

* The app provides future timeline entries in five-minute increments 
  that ClockKit uses to update the complications automatically.
  
* While the app is running, Coffee Tracker updates its complications 
  whenever the user adds a drink. 
  This updates not just the current complication, 
  but also reloads the entire complication timeline.

* Finally, the app uses background refresh tasks to query 
  HealthKit for any updates to its caffeine samples. 
  The app then updates its data based on any changes.

## Create Timeline Entries

If there's an active complication on the watch face, 
ClockKit calls the data source's methods to keep the complication's timeline filled. 
ClockKit calls the [`getCurrentTimelineEntry(for:withHandler:)`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource/1628051-getcurrenttimelineentry) method 
to get the current complication.

``` swift
// Return the current timeline entry.
func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
    handler(createTimelineEntry(forComplication: complication, date: Date()))
}
```

Then it calls the [`getTimelineEntries(for:after:limit:withHandler:))`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource/1628094-gettimelineentries) method to 
batch load future timeline entries.

``` swift
// Return future timeline entries.
func getTimelineEntries(for complication: CLKComplication,
                        after date: Date,
                        limit: Int,
                        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
    
    let fiveMinutes = 5.0 * 60.0
    let twentyFourHours = 24.0 * 60.0 * 60.0
    
    // Create an array to hold the timeline entries.
    var entries = [CLKComplicationTimelineEntry]()
    
    // Calculate the start and end dates.
    var current = date.addingTimeInterval(fiveMinutes)
    let endDate = date.addingTimeInterval(twentyFourHours)
    
    // Create a timeline entry for every five minutes from the starting time.
    // Stop once you reach the limit or the end date.
    while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
        entries.append(createTimelineEntry(forComplication: complication, date: current))
        current = current.addingTimeInterval(fiveMinutes)
    }
    
    handler(entries)
}
```

ClockKit automatically calls these methods when it needs to refill the timeline. 
In Coffee Tracker, both of these methods call the `createTimelineEntry(forComplication:date:)` method
to create the event. 
`createTimelineEntry(forComplication:date:)` then calls `createTemplate(forComplication:date:)`  to build the  template, and wraps the template in a 
[`CLKComplicationTimelineEntry`](https://developer.apple.com/documentation/clockkit/clkcomplicationtimelineentry) object.

## Create and Fill a  Complication Template

ClockKit uses a template-driven user interface.
The system divides the complications into a number of families 
based on their size and capabilities, 
and each family then provides a number of templates that define its layout.
When ClockKit asks the data source for a timeline entry, 
the app must instantiate a template for the specified family, 
and then fill the template with the required data,
before wrapping it in a `CLKComplicationTimelineEntry` object and returning it.

To determine the correct template, the app starts by creating a `switch` statement 
covering all the families supported by the app. 

``` swift
// Select the correct template based on the complication's family.
private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
    switch complication.family {
    case .modularSmall:
        return createModularSmallTemplate(forDate: date)
    case .modularLarge:
        return createModularLargeTemplate(forDate: date)
    case .utilitarianSmall, .utilitarianSmallFlat:
        return createUtilitarianSmallFlatTemplate(forDate: date)
    case .utilitarianLarge:
        return createUtilitarianLargeTemplate(forDate: date)
    case .circularSmall:
        return createCircularSmallTemplate(forDate: date)
    case .extraLarge:
        return createExtraLargeTemplate(forDate: date)
    case .graphicCorner:
        return createGraphicCornerTemplate(forDate: date)
    case .graphicCircular:
        return createGraphicCircleTemplate(forDate: date)
    case .graphicRectangular:
        return createGraphicRectangularTemplate(forDate: date)
    case .graphicBezel:
        return createGraphicBezelTemplate(forDate: date)
    case .graphicExtraLarge:
        if #available(watchOSApplicationExtension 7.0, *) {
            return createGraphicExtraLargeTemplate(forDate: date)
        } else {
            fatalError("Graphic Extra Large template is only available on watchOS 7.")
        }
    @unknown default:
        fatalError("*** Unknown Complication Family ***")
    }
}
```

The app calls a helper method for each family that creates a template the family supports.
The helper method also creates all the data providers needed to fill the template. 
For example, the following helper method creates a graphical corner template.

``` swift
// Return a graphic template that fills the corner of the watch face.
private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
    // Create the data providers.
    let leadingValueProvider = CLKSimpleTextProvider(text: "0")
    leadingValueProvider.tintColor = data.color(forCaffeineDose: 0.0)
    
    let trailingValueProvider = CLKSimpleTextProvider(text: "500")
    trailingValueProvider.tintColor = data.color(forCaffeineDose: 500.0)
    
    let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
    let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
    mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
    let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
    
    let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
    let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                               gaugeColors: [.green, .yellow, .red],
                                               gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                               fillFraction: percentage)
    
    // Create the template using the providers.
    let template = CLKComplicationTemplateGraphicCornerGaugeText()
    template.leadingTextProvider = leadingValueProvider
    template.trailingTextProvider = trailingValueProvider
    template.outerTextProvider = combinedMGProvider
    template.gaugeProvider = gaugeProvider
    return template
}
```

This example creates a curved gauge with text outside it. 
The gauge is a graphical element, like a thermometer or progress bar.
To fill the template, the app supplies a gauge provider, 
which specifies the gauge's start value, end value, current value, 
and the color gradient used by the gauge. 
The app also provides two text providers for the labels at the start and end of the gauge.
Finally, it provides another text provider for the main text.
Depending on the watch face, the gauge and text may use the specified colors to provide additional information.

  
## Reload the Timeline
  
The `CoffeeData` model object declares `currentDrinks`  as a `@Published` property. 
  
``` swift
// Because this is @Published property,
// Combine notifies any observers when a change occurs.
@Published public var currentDrinks = [Drink]()
```
  
Therefore, `currentDrinks` acts as a publisher, alerting any subscribers of any changes. 
For example, SwiftUI uses the publisher to trigger updates to the main view.
  
However, the app can also add its own subscribers, 
letting its code respond whenever the `currentDrinks` array changes.
For example, the  `CoffeeData` class's adds a sink to the `currentDrinks` publisher.
That sink executes a block of code whenever the publisher changes.
  
``` swift
// Add a subscriber to currentDrinks that responds whenever currentDrinks changes.
updateSink = $currentDrinks.sink { [unowned self] _ in
    
    // Update any complications on active watch faces.
    let server = CLKComplicationServer.sharedInstance()
    for complication in server.activeComplications ?? [] {
        server.reloadTimeline(for: complication)
    }
    
    // Begin saving the data.
    self.save()
}
```
  
In this case, the sink gets a list of active complications from the complication server. 
It tells the complication to reload its timeline, 
and ClockKit deletes the complication's entire timeline and reloads the timeline's data.
  
## Schedule Background Refresh Tasks
  
To keep the app up to date with HealthKit, Coffee Tracker schedules a background refresh task 
every time the app goes into the background. 
  
``` swift
// Call when the app goes to the background.
func applicationDidEnterBackground() {
    // Schedule a background refresh task to update the complications.
    scheduleBackgroundRefreshTasks()
}
```
  
The `scheduleBackgroundRefreshTasks` helper method schedules a background refresh update 
task for 15 minutes in the future.

``` swift
// Schedule the next background refresh task.
func scheduleBackgroundRefreshTasks() {
    
    // Get the shared extension object.
    let watchExtension = WKExtension.shared()
    
    // If there is a complication on the watch face, the app should get at least four
    // updates an hour. So calculate a target date 15 minutes in the future.
    let targetDate = Date().addingTimeInterval(15.0 * 60.0)
    
    // Schedule the background refresh task.
    watchExtension.scheduleBackgroundRefresh(withPreferredDate: targetDate, userInfo: nil) { (error) in
        
        // Check for errors.
        if let error = error {
            print("*** An background refresh error occurred: \(error.localizedDescription) ***")
            return
        }
        
        print("*** Background Task Completed Successfully! ***")
    }
}
```
  
To preserve battery life and maintain performance, 
WatchKit carefully budgets each app's time for background tasks. 
In general, if an app has a complication on the active watch face, it can safely schedule four background refresh tasks per hour.
  
When the background task occurs, the system calls the extension delegate's [`handle(_:)`](https://developer.apple.com/documentation/watchkit/wkextensiondelegate/1650877-handle) method.

## Handle Background Refresh Tasks

The app queries HealthKit for any changes, including any samples that have been deleted from HealthKit.
  
``` swift
// check for updates from HealthKit
let model = CoffeeData.shared

model.healthKitController.loadNewDataFromHealthKit {
    // Schedule the next background update.
    self.scheduleBackgroundRefreshTasks()
    
    // Mark the task as ended, and request an updated snapshot.
    backgroundTask.setTaskCompletedWithSnapshot(true)
}
```

After it has received and processed the data, the app schedules a new background task, 
and calls the current task's [`setTaskCompletedWithSnapshot(_:)`](https://developer.apple.com/documentation/watchkit/wkrefreshbackgroundtask/2868454-settaskcompletedwithsnapshot) method.
The app passes `true` to schedule an update to the app's snapshot, updating the apps appearance in the dock.

The app also take the opportunity to check for HealthKit updates whenever 
the app enters the foreground.

``` swift
// Download updates from HealthKit whenever the app enters the foreground.
func applicationWillEnterForeground() {
    
    // Make sure the app has requested authorization.
    let model = CoffeeData.shared
    model.healthKitController.requestAuthorization { (success) in
        
        // Check for errors.
        if !success { fatalError("*** Unable to authenticate HealthKit ***") }
        
        // check for updates from HealthKit
        model.healthKitController.loadNewDataFromHealthKit {}
    }
}
```

## Test Background Updates

To test the background updates, first make sure the Coffee Tracker complication appears on the active watch face. 
Then build and run the app in the simulator, and follow these steps:

1. Add one or more drinks using the app's main view.
2. Click the Digital Crown to send the app to the background.
3. Open Settings, and scroll down to Health > Health Data > Nutrition > Caffeine. 
    Settings should show all the drinks you added to the app.
4. Click Delete Caffeine Data to clear all the caffeine samples from HealthKit.
5. Navigate back to the watch face. 

Coffee Tracker should update the complication within 15 minutes; however, the update may be delayed based on the system's current state.
