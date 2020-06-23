# Receiving Voice and Text Communications on a Local Network

Provide voice and text communication on a local network isolated from Apple Push Notification service by adopting Local Push Connectivity.

## Overview

- Note: This sample code project is associated with WWDC 2020 session [10113: Build Local Push Connectivity for Constrained Networks](http://developer.apple.com/wwdc20/10113).

This sample app shows how to implement and use Local Push Connectivity within a messaging app. The sample workspace contains two app components:

- `SimplePush` — An iOS app that uses Local Push Connectivity to provide text messaging and VoIP services.
- `SimplePushServer` — A lightweight Swift server that simulates the functions of a messaging server by routing messages and calls between clients.

The `SimplePush` app maintains two connections to the server:

- Notification Channel — A TCP connection maintained by the [`NEAppPushProvider`](https://developer.apple.com/documentation/networkextension/neapppushprovider) that provides functionality similar to Apple Push Notification service (APNs) when on a local Wi-Fi network.
- Control Channel — A TCP connection maintained by the iOS app and used to send app control data to the server.

To run the sample, you will need a macOS device to operate as the server, and two iOS devices to communicate with each other, all on the same Wi-Fi network.

## Configure the Sample Code Project

Apps using Local Push Connectivity require the [App Push Provider entitlement](https://developer.apple.com/contact/request/network-extension-app-push-provider) entitlement.

After receiving the entitlement:

1. Log in to your account on the Apple Developer website and create a new provisioning profile that includes the App Push Provider entitlement.
2. Import the newly created provisioning profile into Xcode.
3. Update the `pushProviderBundleIdentifier` of the `NEAppPushManager` in `PushConfigurationManager.swift`.
4. In the Xcode projects for the `SimplePushKit` and `SimplePushServer` apps, set your Apple Development Team targets.

## Build and Run the Sample Server

Select the `SimplePushServer` build scheme and select your macOS machine as the run destination. After starting the server, the console displays the ports used by the server.

## Build, Run, and Configure the Sample App

With the server running, select the `SimplePush` iOS build scheme and run the project on your iOS device. When `SimplePush` starts, update the app’s settings to connect to the server.

1. Tap the Settings button and enter the following information:
2. Enter the Server Address, which is the IP address or hostname of the macOS computer where you’re running the `SimplePushServer`.
3. Enter the App Push Provider SSID, which is the SSID of your local Wi-Fi network, on which the `NEAppPushProvider` runs.

After configuring those settings, the “App Push Provider - Active” setting displays “Yes” when `NEAppPushProvider` is running. You should perform the steps above on at least two iOS devices so you can test and observe message exchanges between clients.
