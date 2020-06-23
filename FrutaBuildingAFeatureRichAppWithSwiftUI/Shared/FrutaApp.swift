/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The single entry point for the Fruta app on all platforms.
*/

import SwiftUI
#if APPCLIP
import AppClip
import CoreLocation
#endif

@main
struct FrutaApp: App {
    @StateObject private var model = FrutaModel()
    
    #if !APPCLIP
    @StateObject private var store = Store()
    #endif
    
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
}
