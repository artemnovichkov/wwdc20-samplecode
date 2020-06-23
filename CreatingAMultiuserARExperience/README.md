# Creating a Multiuser AR Experience

Enable nearby devices to share an AR experience by using a host-guest multiuser strategy. 

## Overview

![Diagram showing AR experiences on two devices viewing, from two different perspectives, the same virtual red panda character sitting on a real table, after an ARWorldMap is transmitted from one device to the other.](Documentation/ConceptArt.png)

This sample app demonstrates a simple shared AR experience for two or more iOS 12 devices. Before exploring the code, try building and running the app to familiarize yourself with the user experience it demonstrates:

1. Run the app on one device. You can look around the local environment, and tap to place a virtual 3D character on real-world surfaces. (Tap again to place multiple copies of the character.)
2. Run the app on a second device. On both device screens, a message indicates that they have automatically joined a shared session.
3. Tap the Send World Map button on one device. Make sure the other device is in an area that the first device visited before sending the map, or has a similar view of the surrounding environment.
4. The other device displays a message indicating that it has received the map and is attempting to use it. When that process succeeds, both devices show virtual content at the same real-world positions, and tapping on either device places virtual content visible to both.

Follow the steps below to see how this app uses the [`ARWorldMap`][0] class to save and restore ARKit's spatial mapping state, and the [`MultipeerConnectivity`][1] framework to send world maps between nearby devices. 

[0]:https://developer.apple.com/documentation/arkit/arworldmap
[1]:https://developer.apple.com/documentation/multipeerconnectivity

## Getting Started

Requires Xcode 10.0, iOS 12.0 and two or more iOS devices with A9 or later processors.

## Run the AR Session and Place AR Content

This app extends the basic workflow for building an ARKit app. (For details, see [Building Your First AR Experience][10].) It defines an [`ARWorldTrackingConfiguration`][11] with plane detection enabled, then runs that configuration in the [`ARSession`][12] attached to the [`ARSCNView`][13] that displays the AR experience.

When [`UITapGestureRecognizer`][14] detects a tap on the screen, the [`handleSceneTap`](x-source-tag://PlaceCharacter) method uses ARKit hit-testing to find a 3D point on a real-world surface, then places an [`ARAnchor`][15] marking that position. When ARKit calls the delegate method [`renderer(_:didAdd:for:)`][16], the app loads a 3D model for [`ARSCNView`][13] to display at the anchor's position.

[10]:https://developer.apple.com/documentation/arkit/world_tracking/tracking_and_visualizing_planes
[11]:https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration
[12]:https://developer.apple.com/documentation/arkit/arsession
[13]:https://developer.apple.com/documentation/arkit/arscnview
[14]:https://developer.apple.com/documentation/uikit/uitapgesturerecognizer
[15]:https://developer.apple.com/documentation/arkit/aranchor
[16]:https://developer.apple.com/documentation/arkit/arscnviewdelegate/2865794-renderer

## Connect to Peer Devices

The sample [`MultipeerSession`](x-source-tag://MultipeerSession) class provides a simple abstraction around the [MultipeerConnectivity][20] features this app uses. After the main view controller creates a `MultipeerSession` instance (at app launch), it starts running an [`MCNearbyServiceAdvertiser`][21] to broadcast the device's ability to join multipeer sessions and an [`MCNearbyServiceBrowser`][22] to find other devices:

``` swift
session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
session.delegate = self

serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
serviceAdvertiser.delegate = self
serviceAdvertiser.startAdvertisingPeer()

serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerSession.serviceType)
serviceBrowser.delegate = self
serviceBrowser.startBrowsingForPeers()
```
[View in Source](x-source-tag://MultipeerSetup)

When the [`MCNearbyServiceBrowser`][22] finds another device, it calls the [`browser(_:foundPeer:withDiscoveryInfo:)`][23] delegate method. To invite that other device to a shared session, call the browser's [`invitePeer(_:to:withContext:timeout:)`][24] method:

``` swift
public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
    // Invite the new peer to the session.
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
}
```
[View in Source](x-source-tag://FoundPeer)

When the other device receives that invitation, [`MCNearbyServiceAdvertiser`][21] calls the [`advertiser(_: didReceiveInvitationFromPeer:withContext:invitationHandler:`][25] delegate method. To accept the invitation, call the provided `invitationHandler`:

``` swift
func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    // Call handler to accept invitation and join the session.
    invitationHandler(true, self.session)
}
```
[View in Source](x-source-tag://AcceptInvite)

- Important: This app automatically joins the first nearby session it finds. Depending on the kind of shared AR experience you want to create, you may want to more precisely control broadcasting, invitation, and acceptance behavior. See the [MultipeerConnectivity][20] documentation for details.

In a multipeer session, all participants are by definition equal peers; there is no explicit separation of devices into host and guest roles. However, you may wish to define such roles for your own AR experience. For example, a multiplayer game design might require a host role to arbitrate gameplay. If you need to separate peers by role, you can choose a way to do so that fits the design of your app. For example:

- Have the user choose whether to act as a host or guest before starting a session. The host uses [`MCNearbyServiceAdvertiser`][21] to broadcast availability, and guests use [`MCNearbyServiceBrowser`][22] to find a host to join.
- Join a session as peers, then negotiate between peers to nominate a host. (This approach can be helpful for designs that need a host role but also allow peers to join or leave at any time.)


[20]:https://developer.apple.com/documentation/multipeerconnectivity
[21]:https://developer.apple.com/documentation/multipeerconnectivity/mcnearbyserviceadvertiser
[22]:https://developer.apple.com/documentation/multipeerconnectivity/mcnearbyservicebrowser
[23]:https://developer.apple.com/documentation/multipeerconnectivity/mcnearbyservicebrowserdelegate/1406926-browser
[24]:https://developer.apple.com/documentation/multipeerconnectivity/mcnearbyservicebrowser/1406944-invitepeer
[25]:https://developer.apple.com/documentation/multipeerconnectivity/mcnearbyserviceadvertiserdelegate/1406971-advertiser


## Capture and Send the AR World Map

An [`ARWorldMap`][0] object contains a snapshot of all the spatial mapping information that ARKit uses to locate the user's device in real-world space. Reliably sharing a map to another device requires two key steps: finding a good time to capture a map, and capturing and sending it.

ARKit provides a [`worldMappingStatus`][30] value that indicates whether it's currently a good time to capture a world map (or if it's better to wait until ARKit has mapped more of the local environment). This app uses that value to provide visual feedback on its Send World Map button:

``` swift
switch frame.worldMappingStatus {
case .notAvailable, .limited:
    sendMapButton.isEnabled = false
case .extending:
    sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
case .mapped:
    sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
@unknown default:
    sendMapButton.isEnabled = false
}
mappingStatusLabel.text = frame.worldMappingStatus.description
```
[View in Source](x-source-tag://CheckMappingStatus)

When the user taps the Send World Map button, the app calls [`getCurrentWorldMap`][31] to capture the map from the running ARSession, then serializes it to a [`Data`][32] object with [`NSKeyedArchiver`][33] and sends it to other devices in the multipeer session:

``` swift
sceneView.session.getCurrentWorldMap { worldMap, error in
    guard let map = worldMap
        else { print("Error: \(error!.localizedDescription)"); return }
    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        else { fatalError("can't encode map") }
    self.multipeerSession.sendToAllPeers(data)
}
```
[View in Source](x-source-tag://ReceiveData)

[30]:https://developer.apple.com/documentation/arkit/arframe/2990930-worldmappingstatus
[31]:https://developer.apple.com/documentation/arkit/arsession/2968206-getcurrentworldmap
[32]:https://developer.apple.com/documentation/foundation/data
[33]:https://developer.apple.com/documentation/foundation/nskeyedarchiver

## Receive and Relocalize to the Shared Map

When a device receives data sent by another participant in the multipeer session, the [`session(_:didReceive:fromPeer:)`][40] delegate method provides that data. To make use of it, the app uses [`NSKeyedUnarchiver`][41] to deserialize an [`ARWorldMap`][0] object, then creates and runs a new [`ARWorldTrackingConfiguration`][11] using that map as the [`initialWorldMap`][42]:

``` swift
if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
    // Run the session with the received world map.
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    configuration.initialWorldMap = worldMap
    sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    
    // Remember who provided the map for showing UI feedback.
    mapProvider = peer
}
```
[View in Source](x-source-tag://UnarchiveWorldMap)

ARKit then attempts to *relocalize* to the new world map—that is, to reconcile the received spatial-mapping information with what it senses of the local environment. For best results: 

1. Thoroughly scan the local environment on the sending device before sharing a world map.
2. Place the receiving device next to the sending device, so that both see the same view of the environment.

[40]:https://developer.apple.com/documentation/multipeerconnectivity/mcsessiondelegate/1406934-session
[41]:https://developer.apple.com/documentation/foundation/nskeyedunarchiver
[42]:https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/2968180-initialworldmap

## Share AR Content and User Actions

Sharing the world map also shares all existing anchors. In this app, this means that as soon as a receiving device relocalizes to the world map, it shows all the 3D characters that were placed by the sending device before it captured and sent a world map. However, recording and transmitting a world map and relocalizing to a world map are time-consuming, bandwidth-intensive operations, so you should take those steps only once, when a new device joins a session. 

To create an ongoing shared AR experience, where each user's actions affect the AR scene visible to other users, after each device relocalizes to the same world map you should share only the information needed to recreate each user action. For example, in this app the user can tap to place a virtual 3D character in the scene. That character is static, so all that is needed to place the character on another participating device is the character's position and orientation in world space.

This app communicates virtual character positions by sharing [`ARAnchor`][15] objects between peers. When one user taps in the scene, the app creates an anchor and adds it to the local [`ARSession`][12], then serializes that [`ARAnchor`][15] using [`NSKeyedArchiver`][32] and sends it to other devices in the multipeer session:

``` swift
// Place an anchor for a virtual character. The model appears in renderer(_:didAdd:for:).
let anchor = ARAnchor(name: "panda", transform: hitTestResult.worldTransform)
sceneView.session.add(anchor: anchor)

// Send the anchor info to peers, so they can place the same content.
guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
    else { fatalError("can't encode anchor") }
self.multipeerSession.sendToAllPeers(data)
```
[View in Source](x-source-tag://PlaceCharacter)

When other peers receive data from the multipeer session, they test for whether that data contains an archived [`ARAnchor`][15]; if so, they decode it and add it to their session:

``` swift
if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
    // Add anchor to the session, ARSCNView delegate adds visible content.
    sceneView.session.add(anchor: anchor)
}
```
[View in Source](x-source-tag://ReceiveData)

This is just one strategy for adding dynamic features to a shared AR experience—many other strategies are possible. Choose one that fits the user interaction, rendering, and networking requirements of your app. For example, a game where users throw projectiles in the AR world space might define custom data types with attributes like initial position and velocity, then use Swift's [`Codable`][50] protocols to serialize that information to a binary representation for sending over the network. 

[50]:https://developer.apple.com/documentation/swift/codable
