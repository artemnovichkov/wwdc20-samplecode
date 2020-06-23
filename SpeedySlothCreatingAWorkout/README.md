# SpeedySloth: Creating a Workout

Start, stop, and to save workouts on Apple Watch with the Workout Builder API.

## Overview

This sample demonstrates how to create an Apple Watch workout app using the Workout Builder API. The sample displays real-time data, such as heart rate, distance traveled, and elapsed time during an active workout. The user can tap on a button on the inital interface to start the workout, and swipe right on the workout interface to bring up the menu to pause or stop the workout. In the sample, all the business logic of interfacing with HealthKit and managing the workout is encapsulated in the `WorkoutManager` object.

## Configure the Sample Code Project

To build and run this sample on your device, you must first update the bundle ID in the `Info.plist` file in the WatchKit Extension target. Follow these steps to change the bundle ID:

1. Open the sample with the latest version of Xcode.
2. Select the top-level project.
3. For the three targets, select the correct team on the Signing & Capabilities tab (next to Team) to let Xcode automatically manage your provisioning profile. 
4. Make a note of the Bundle Identifier of the WatchKit App target.
5. Open the `Info.plist` file of the WatchKit Extension target, and change the value of the `NSExtension > NSExtensionAttributes > WKAppBundleIdentifier` key to the bundle ID you noted in the previous step.
6. Make a clean build and run the sample app on your device. 

## Request Authorization

Workout apps access the HealthKit data store for real-time data and to save workouts. Apps that use the HealthKit framework should follow the steps in [Setting Up HealthKit](https://developer.apple.com/documentation/healthkit/setting_up_healthkit). In particular, an app must request authorization from the user to access data and save the workout:
``` swift
// The quantity type to write to the health store.
let typesToShare: Set = [
    HKQuantityType.workoutType()
]

// The quantity types to read from the health store.
let typesToRead: Set = [
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
]

// Request authorization for those quantity types.
healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
    // Handle error.
}
```
[View in Source](x-source-tag://RequestAuthorization)

## Create the Workout Session and Live Workout Builder
The sample first creates an [`HKWorkoutConfiguration`]( https://developer.apple.com/documentation/healthkit/hkworkoutconfiguration ) object, and sets its properties to describe the type of activity corresponding to this workout. In the case below, the sample sets the `activityType` property to `.running` to represent a running workout activity. HealthKit provides constants for dozens of popular workout and fitness activities.
``` swift
let configuration = HKWorkoutConfiguration()
configuration.activityType = .running
configuration.locationType = .outdoor
```
[View in Source](x-source-tag://WorkoutConfiguration)

Next, the sample creates the [`HKWorkoutSession`]( https://developer.apple.com/documentation/healthkit/hkworkoutsession ) and the [`HKLiveWorkoutBuilder`]( https://developer.apple.com/documentation/healthkit/hkliveworkoutbuilder ) objects. These two objects are declared as member variables of the `WorkoutManager`. 
``` swift
let healthStore = HKHealthStore()
var session: HKWorkoutSession!
var builder: HKLiveWorkoutBuilder!
```
[View in Source](x-source-tag://DeclareSessionBuilder)

The workout session is required in order to save a workout in the HealthKit store. This initialization throws an exception when the workout configuration parameter is invalid. Then, the sample asks the workout session object for the associated `HKLiveWorkoutBuilder` object, which automates the collection of HealthKit quantity types that the sample app displays to the user during the workout.
``` swift
do {
    session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
    builder = session.associatedWorkoutBuilder()
} catch {
    // Handle any exceptions.
    return
}

// Setup session and builder.
session.delegate = self
builder.delegate = self
```
[View in Source](x-source-tag://CreateWorkout)

## Set the Data Source
The sample initializes a new [`HKLiveWorkoutDataSource`]( https://developer.apple.com/documentation/healthkit/hkliveworkoutdatasource ) object, configured with the same workout configuration object used earlier in creating the workout session. As a result, the data source infers the quantity types to collect. The sample sets the `HKLiveWorkoutDataSource` object as the workout builder object's data source. 
``` swift
builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                             workoutConfiguration: workoutConfiguration())
```
[View in Source](x-source-tag://SetDataSource)

## Start the Session and the Builder
The workout session and workout builder objects are now fully set up, so the sample starts the workout session and the workout builder's data collection.
``` swift
session.startActivity(with: Date())
builder.beginCollection(withStart: Date()) { (success, error) in
    // The workout has started.
}
```
[View in Source](x-source-tag://StartSession)

## Update the User Interface
`WorkoutManager` is implemented as an [`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject), and publishes the properties that are needed to update the user interface.
``` swift
@Published var heartrate: Double = 0
@Published var activeCalories: Double = 0
@Published var distance: Double = 0
@Published var elapsedSeconds: Int = 0
```
[View in Source](x-source-tag://Publishers)

When HealthKit has new quantities available, it calls the `HKLiveWorkoutBuilderDelegate` protocol's [`workoutBuilder(_:didCollectDataOf:)`]( https://developer.apple.com/documentation/healthkit/hkliveworkoutbuilderdelegate/2962897-workoutbuilder ) method. The sample iterates on the collected quantity types to retrieve the most recent values, then updates the published properties. For example, the sample uses the following process to publish new heart rate values. First, the sample calls the workout builder's' [`statistics(for:)`]( https://developer.apple.com/documentation/healthkit/hkworkoutbuilder/2962922-statistics ) method to obtain the  [`HKStatistics`]( https://developer.apple.com/documentation/healthkit/hkstatistics  ) object corresponding to the quantity type in the current iteration.
``` swift
let statistics = workoutBuilder.statistics(for: quantityType)
```
[View in Source](x-source-tag://GetStatistics)

Then, the sample retrieves the most recent value collected from the `HKStatistics` object, rounds it, and publishes the new value by setting the `heartrate` published member variable to the new value.
``` swift
let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
let roundedValue = Double( round( 1 * value! ) / 1 )
self.heartrate = roundedValue
```
[View in Source](x-source-tag://SetLabel)

## Update the Workout Timer
To let the user know how long the workout has been in progress, the sample app implements a timer display that shows the elapsed time in seconds. A [`TimerPublisher`](https://developer.apple.com/documentation/foundation/timer/timerpublisher) drives the display of the elapsed time. To ensure accuracy, the timer fires at 0.1 second intervals, even though the display shows integer seconds only. 
``` swift
// The cancellable holds the timer publisher.
var start: Date = Date()
var cancellable: Cancellable?
var accumulatedTime: Int = 0

// Set up and start the timer.
func setUpTimer() {
    start = Date()
    cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
        .autoconnect()
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds = self.incrementElapsedTime()
        }
}

// Calculate the elapsed time.
func incrementElapsedTime() -> Int {
    let runningTime: Int = Int(-1 * (self.start.timeIntervalSinceNow))
    return self.accumulatedTime + runningTime
}
```
[View in Source](x-source-tag://TimerSetup)

## Save the Workout
When the user has finished working out, they tap on the End button in the menu. In response, the sample ends the workout session and stops collecting data. The sample calls the workout session's [`end()`](https://developer.apple.com/documentation/healthkit/hkworkoutsession/2962932-end) method. `HealthKit` will call the workout session delegate's [`workoutSession(_:didChangeTo:from:date:)`](https://developer.apple.com/documentation/healthkit/hkworkoutsessiondelegate/1627958-workoutsession) callback method. In this method, the sample calls the workout builder's [`endCollection(withEnd:completion:)`]( https://developer.apple.com/documentation/healthkit/hkworkoutbuilder/3000762-endcollection ) method to end the collection of data. Then the sample saves the workout along with the associated collected samples and events by calling [`finishWorkout(completion:)`]( https://developer.apple.com/documentation/healthkit/hkworkoutbuilder/3000764-finishworkout ). In the completion block, the sample resets the workout state.
``` swift
if toState == .ended {
    print("The workout has now ended.")
    builder.endCollection(withEnd: Date()) { (success, error) in
        self.builder.finishWorkout { (workout, error) in
            // Optionally display a workout summary to the user.
            self.resetWorkout()
        }
    }
}
```
[View in Source](x-source-tag://SaveWorkout)
