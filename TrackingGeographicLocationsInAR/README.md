# Tracking Geographic Locations in AR

Track specific geographic areas of interest and render them in an AR experience.

## Overview

Geo-tracking configuration ([`ARGeoTrackingConfiguration`][1]) combines GPS, the device's compass, and world-tracking features to enable back-camera AR experiences to track specific geographic locations. By giving ARKit a latitude and longitude (and optionally, altitude), an app declares interest in a specific location on the map. ARKit tracks this location in the form of a *location anchor* ([`ARGeoAnchor`][2]), which an app can refer to in an AR experience. ARKit provides the location anchor's coordinates with respect to the scene, which allows an app to render virtual content at its real-world location or trigger other interactions. For example, when the user approaches a location anchor, an app reveals a virtual signpost that explains a historic event that occurred there. Or, an app might render a virtual anchor in a series of location anchors that connect, to form a street route.

In this sample app, the user marks spots on a map or camera feed to create a collection of anchors they view in an AR experience. By rendering those anchors as virtual content in an AR view, the user can see a nearby anchor through the camera feed, move to its physical location, and continue to any subsequent anchors in the collection. If a virtual anchor that the user is moving toward isn't visible in the camera feed, the user can refer to its pin in the map view and advance until the virtual anchor becomes visible.

![Figure of an AR app showing two views. The upper view displays a camera feed that captures a busy city intersection. A series of floating blue buoys form a path leading the user to turn right. In the lower view, a top-down map provides an alternate view of the same scene. Dots on the map correspond to the buoys seen in the camera feed which appear to lead the user through the city.](Documentation/hero-image.png)

## Ensure Device Support

Geo tracking requires an iOS/iPadOS 14 device with A12 Bionic chip or later, and cellular (GPS) capability. At the application entry point (see the sample project's `AppDelegate.swift`), the sample app prevents running an unsupported configuration by checking whether the device supports geo tracking.

``` swift
if !ARGeoTrackingConfiguration.isSupported {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
}
```

If the device doesn't support geo tracking, the sample project will stop. Optionally, the app presents the user with an error message and continue the experience at a limited capacity without geo tracking.

## Display an AR View and Map View

As an AR app, the sample project renders location anchors using an [`ARView`][3]. To reinforce the correspondence between geographic locations and positions in the session's local space, the sample project also displays a map view ([`MKMapView`][4]) that marks the anchors from a top-down perspective. The app displays both views simultaneously by using a stack view ([`UIStackView`][5]) with the camera feed on top. See the sample's `View Controller Scene` within the project's `Main.storyboard`.

## Check Availability and Run a Session

To place location anchors with precision, geo tracking requires a better understanding of the user’s geographic location than is possible with GPS alone. Based on a particular GPS coordinate, ARKit downloads batches of imagery that depict the physical environment in that area and assist the session with determining the user’s precise geographic location.

This *localization imagery* captures the view mostly from public streets and routes accessible by car. As a result, geo tracking doesn’t support areas within the city that are gated or accessible only to pedestrians, as ARKit lacks localization imagery there.

Because localization imagery depicts specific regions on the map, geo tracking only supports areas only from which Apple has collected localization imagery in advance. Before starting a session, the sample project checks whether geo-tracking supports the user's location by calling [`checkAvailability(completionHandler:)`][6].

``` swift
ARGeoTrackingConfiguration.checkAvailability { (available, error) in
    if !available {
        let errorDescription = error?.localizedDescription ?? ""
        let recommendation = "Please try again in an area where geo tracking is supported."
        let restartSession = UIAlertAction(title: "Restart Session", style: .default) { (_) in
            self.restartSession()
        }
        self.alertUser(withTitle: "Geo tracking unavailable",
                       message: "\(errorDescription)\n\(recommendation)",
                       actions: [restartSession])
    }
}
```

ARKit requires a network connection to download localization imagery. The [`checkAvailability`][6] function will return `false` if a network connection is unavailable. If geo tracking is available, the sample project runs a session.

``` swift
arView.session.run(ARGeoTrackingConfiguration())
```

- Note: If geo tracking is unavailable in the user's current location, an app can suggest an alternative area if [`checkAvailability(at:completionHandler:)`][7] returns `true` for a nearby location.

## Monitor and React to Geo-Tracking Status

A geo-tracking session experiences a number of different states. To monitor state changes, the sample project implements the [`session:didChangeGeoTrackingStatus:`][8] callback.

``` swift
func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
    var text = geoTrackingStatus.state.description
```
[View in Source](x-source-tag://GeoTrackingStatus)

Each phase in the geo-tracking lifecycle requires coordination with the user, so the sample app displays user instructions based on state prominently. 

``` swift
self.trackingStateLabel.text = text
```

As an example, it's possible for the user to cross into an area where geo tracking is unavailable while the session is running. In this situation, ARKit provides the status reason [`.notAvailableAtLocation`][9]. To enable the session to continue, the sample project presents text to guide the user accordingly. 

``` swift
case .notAvailableAtLocation: return "Geo tracking is unavailable here. Please return to your previous location to continue"
```

## Assist the User with Visual Localization

After the session acquires a confident GPS position for the user (see [`.waitingForLocation`][13]), the session moves to [`.localizing`][12] where the session downloads localization imagery for the user’s geographic location and compares it with captures from the device’s camera. This process is referred to as *visual localization*. When ARKit succeeds in matching this imagery with captures from the camera, the state moves to [`.localized`][11] and the app is free to create location anchors.

As ARKit downloads localization imagery, the session is in state reason [`.geoDataNotLoaded`][10]. The sample project presents text to the user that requests they wait for the download to complete. 

``` swift
case .geoDataNotLoaded: return "Downloading localization imagery. Please wait"
```

- Note: If [`.geoDataNotLoaded`][10] persists for too long, it may indicate a network issue. If a reasonable amount of time elapses in this state reason, an app may ask the user to check the internet connection.

To establish visual localization, the user must move the device in ways that acquire the camera captures that ARKit needs. The sample project displays a message to elicit the right user movements. If the session detects the user is pointing the device too low, the sample project asks the user to raise the device and focus on distinct visuals, like structures, or signs.

``` swift
case .devicePointedTooLow: return "Point the camera at a nearby building"
```

If visual localization is running longer than usual, the sample project asks the user to avoid pointing the device at objects that are too general, like trees. 

``` swift
case .visualLocalizationFailed: return "Point the camera at a building unobstructed by trees or other objects"
```

To expedite visual localization, avoid pointing the device at real-world objects that are transient, like parked cars, or a construction site. Because lighting conditions can affect visual localization, avoid geo tracking at night.

When ARKit confidently matches its localization imagery with captures from the camera, the state moves to [`.localized`][11], and the app is free to use location anchors. Before creating an anchor, the sample project checks to ensure the state is [`.localized`][11].

``` swift
var isGeoTrackingLocalized: Bool {
    if let status = arView.session.currentFrame?.geoTrackingStatus, status.state == .localized {
        return true
    }
    return false
}
```

## Create an Anchor When the User Taps the Map

The sample project acquires the user's geographic coordinate (`CLLocationCoordinate2D`) from the map view at the screen location where the user tapped.

``` swift
func handleTapOnMapView(_ sender: UITapGestureRecognizer) {
    let point = sender.location(in: mapView)
    let location = mapView.convert(point, toCoordinateFrom: mapView)
```

With the user's latitude and longitude, the sample project creates a location anchor. 

``` swift
geoAnchor = ARGeoAnchor(coordinate: location)
```

Because the map view returns a 2D coordinate with no altitude, the sample calls [`init(coordinate:)`][19] which defaults the location anchor's altitude to ground level.

To begin tracking the anchor, the sample project adds it to the session.

``` swift
arView.session.add(anchor: geoAnchor)
```

The sample project listens for the location anchor in [`session(didAdd:)`][18] and visualizes it in AR by adding a placemark entity to the scene.

``` swift
func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for geoAnchor in anchors.compactMap({ $0 as? ARGeoAnchor }) {
        
        // Add an AR placemark visualization for the geo anchor.
        arView.scene.addAnchor(Entity.placemarkEntity(for: geoAnchor))
```

To establish visual correspondence in the map view, the sample project adds an [`MKOverlay`][17] that represents the anchor on the map.

``` swift
let anchorIndicator = AnchorIndicator(center: geoAnchor.coordinate)
mapView.addOverlay(anchorIndicator)
```

## Create an Anchor When the User Taps the AR View

When the user taps the camera feed, the sample project casts a ray at the screen tap-location to determine its intersection with a real-world surface. 

``` swift
if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
```

The raycast result's translation describes the intersection's position in ARKit's local coordinate space. To convert that point to a geographic location, the sample project calls the session-provided utility [`getGeoLocation(forPoint:)`][16].

``` swift
arView.session.getGeoLocation(forPoint: worldPosition) { (location, altitude, error) in
```

Then, the sample project creates a location anchor with the result. Because the result includes altitude, the sample project calls the [`init(coordinate:altitude:)`][20] anchor initializer.

## Assess Geo-Tracking Accuracy

To ensure the best possible user experience, an app must monitor and react to the geo-tracking [`accuracy`][14]. When possible, the sample project displays the accuracy as part of its state messaging to the user. The session populates accuracy in its [`geoTrackingStatus`][21] in state [`.localized`][11].

``` swift
if geoTrackingStatus.state == .localized {
    text += ", Accuracy: \(geoTrackingStatus.accuracy.description)"
```

When accuracy is [`.low`][15], an app renders location anchors using an asset that’s more forgiving if ARKit is off by a small distance. For example, the sample app renders a location anchor as a large ball several meters in the air rather than an arrow that rests its point on a real-world surface. 

## Center the Map as the User Moves

Handling geo-location updates from Core Location isn't necessary for an AR experience, but the sample project does this to center the user in the map view. When the user moves around, Core Location notifies the delegate of any updates in geographic position. The sample project monitors this event by implementing the relevant callback.

``` swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
```

When the user's position changes, the sample project pans the map to center the user.

``` swift
let camera = MKMapCamera(lookingAtCenter: location.coordinate,
                         fromDistance: CLLocationDistance(250),
                         pitch: 0,
                         heading: mapView.camera.heading)
mapView.setCamera(camera, animated: false)
```


[1]:https://developer.apple.com/documentation/arkit/argeotrackingconfiguration
[2]:https://developer.apple.com/documentation/arkit/argeoanchor
[3]:https://developer.apple.com/documentation/realitykit/arview
[4]:https://developer.apple.com/documentation/mapkit/mkmapview
[5]:https://developer.apple.com/documentation/uikit/uistackview
[6]:https://developer.apple.com/documentation/arkit/argeotrackingconfiguration/3571351-checkavailability
[7]:https://developer.apple.com/documentation/arkit/argeotrackingconfiguration/3571350-checkavailability
[8]:https://developer.apple.com/documentation/arkit/arsessionobserver/3580878-session
[9]:https://developer.apple.com/documentation/arkit/argeotrackingstatus/statereason/notavailableatlocation
[10]:https://developer.apple.com/documentation/arkit/argeotrackingstatus/statereason/geodatanotloaded
[11]:https://developer.apple.com/documentation/arkit/arframe/state/localized
[12]:https://developer.apple.com/documentation/arkit/arframe/state/localizing
[13]:https://developer.apple.com/documentation/arkit/argeotrackingstatus/statereason/waitingforlocation
[14]:https://developer.apple.com/documentation/arkit/argeotrackingstatus/3580875-accuracy
[15]:https://developer.apple.com/documentation/arkit/arframe/accuracy/low
[16]:https://developer.apple.com/documentation/arkit/arsession/3571352-getgeolocation
[17]:https://developer.apple.com/documentation/mapkit/mkoverlay
[18]:https://developer.apple.com/documentation/arkit/arsessiondelegate/2865617-session
[19]:https://developer.apple.com/documentation/arkit/argeoanchor/3551718-init
[20]:https://developer.apple.com/documentation/arkit/argeoanchor/3551719-init
[21]:https://developer.apple.com/documentation/arkit/arframe/3580861-geotrackingstatus