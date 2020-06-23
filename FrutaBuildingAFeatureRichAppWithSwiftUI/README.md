# Fruta: Building a Feature-Rich App with SwiftUI

Create a shared codebase to build a multiplatform app that offers widgets and an app clip.


## Overview

- Note: This sample project is associated with WWDC 2020 sessions [10637: Platforms State of the Union](https://developer.apple.com/wwdc20/10637/), [10146: Configure and Link Your App Clips](https://developer.apple.com/wwdc20/10146/), [10120: Streamline Your App Clip](https://developer.apple.com/wwdc20/10120/), [10118: Create App Clips for Other Businesses](https://developer.apple.com/wwdc20/10118/), [10096: Explore Packages and Projects with Xcode Playgrounds](https://developer.apple.com/wwdc20/10096/), and [10028: Meet WidgetKit](https://developer.apple.com/wwdc20/10028/).

The Fruta sample app builds an app for macOS, iOS, and iPadOS that implements [SwiftUI](https://developer.apple.com/documentation/swiftui) platform features like widgets or app clips. Users can order smoothies, save favorite drinks, collect rewards, and browse recipes.

The sample app’s Xcode project includes widget extensions that enable users to add a widget to their iOS Home screen or the macOS Notification Center and view their rewards or a favorite smoothie. The Xcode project also includes an app clip target. With the app clip, users can discover and instantly launch some of the app's functionality on their iPhone or iPad without installing the full app.

The Fruta sample app leverages [Sign in with Apple](https://developer.apple.com/documentation/sign_in_with_apple) and [Apple Pay](https://developer.apple.com/documentation/passkit) to provide a streamlined user experience, and promotes code reuse by bundling shared code and localized assets as [Swift Packages](https://developer.apple.com/documentation/swift_packages).

## Configure the Sample Code Project

To build this project, use Xcode 12.0 with the iOS 14.0 SDK. The runtime requirement is iOS 14.0 or later, or macOS 10.16 or later.

1. To run on macOS, set your team in both the macOS and macOS widget targets’ Signing & Capabilities panes. Xcode manages the provisioning profiles for you.
2. To run on an iOS or iPadOS device, create provisioning profiles for the iOS app, the iOS App Clip, and the iOS widget manually. Be sure to enable App Groups and Sign in with Apple for both the app and the App Clip. Also, open the `iOSClip.entitlements` file and update the value of the [Parent Application Identifiers Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_parent-application-identifiers) to match the iOS app's bundle identifier.
3. The Xcode project includes playgrounds that are configured to run on iOS. To change a playground’s platform, select it in the Project navigator, open the File inspector, and select the desired platform. Next, select the scheme that matches the platform before you build and run the playground.

## Use SwiftUI to Create a Shared Codebase

To create a single app definition that works for multiple platforms, the project defines a structure that conforms to the [App](https://developer.apple.com/documentation/swiftui/app) protocol. Because the `@main` attribute precedes the structure definition, the system recognizes the structure as the entry point into the app. Its computed body property returns a [WindowGroup](https://developer.apple.com/documentation/swiftui/windowgroup) scene that contains the view hierarchy displayed by the app to the user. SwiftUI manages the presentation of the scene and its contents in a platform-appropriate manner.

``` swift
@SceneBuilder var body: some Scene {
    WindowGroup {
        #if APPCLIP
        NavigationView {
            SmoothieMenu()
        }
        .environmentObject(model)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: handleUserActivity)
        #else
        ContentView()
            .environmentObject(model)
            .environmentObject(store)
        #endif
    }
}
```
[View in Source](x-source-tag://SingleAppDefinition)

For more information, see [App Structure and Behavior](https://developer.apple.com/documentation/swiftui/app-structure-and-behavior).

## Offer an App Clip 

On iOS and iPadOS, the Fruta app offers some of its functionality to users who don't have the full app installed as an app clip. The app's Xcode project contains an app clip target, and, instead of duplicating code, reuses code that’s shared across all platforms to build the app clip. In shared code, the project makes use of the Active Compilation Condition build setting to exclude code for targets that don't define the `APPCLIP` value. For example, a method for verifying the user's location is only accessible to the app clip target.

``` swift
#if APPCLIP
func handleUserActivity(_ userActivity: NSUserActivity) {
    guard let incomingURL = userActivity.webpageURL,
          let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems else {
        return
    }
    if let smoothieID = queryItems.first(where: { $0.name == "smoothie" })?.value {
        model.selectSmoothie(id: smoothieID)
    }
    guard let payload = userActivity.appClipActivationPayload,
          let latitudeValue = queryItems.first(where: { $0.name == "latitude" })?.value,
          let longitudeValue = queryItems.first(where: { $0.name == "longitude" })?.value,
          let latitude = Double(latitudeValue), let longitude = Double(longitudeValue) else {
        return
    }
    let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latitude,
                        longitude: longitude), radius: 100, identifier: "smoothie_location")
    payload.confirmAcquired(in: region) { inRegion, error in
        if let error = error {
            print(error.localizedDescription)
            return
        }
        DispatchQueue.main.async {
            model.applePayAllowed = inRegion
        }
    }
}
#endif
```
[View in Source](x-source-tag://ActiveCompilationCondition)

For more information, see [Creating an App Clip](https://developer.apple.com/documentation/app_clips/creating_an_app_clip) and [Developing a Great App Clip](https://developer.apple.com/documentation/app_clips/developing_a_great_app_clip).

## Create a Widget

To allow users to see some of the app's content as a widget on their iOS Home screen or in the macOS Notification Center, the Xcode project contains targets for widget extensions. Both use code that’s shared across all targets.

For more information, see [WidgetKit](https://developer.apple.com/documentation/widgetkit).
