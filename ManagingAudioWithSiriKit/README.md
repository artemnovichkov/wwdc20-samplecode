# Managing Audio with SiriKit

Control audio playback and handle requests to add media using SiriKit Media Intents.

## Overview

- Note: This sample code project is associated with WWDC 2020 session [Expand Your SiriKit Media Intents to More Platforms](https://developer.apple.com/videos/play/wwdc2020/10061/).

## Configure the Sample Code Project

Before you run the sample code project in Xcode:

1. Create an App Group for `com.example.apple-samplecode.ControlAudio.Shared` in your developer portal.

2. Create an App ID for `com.example.apple-samplecode.ControlAudio` in your developer portal and enable it for App Groups, specifying the group you created in the previous step. Additionally, enable SiriKit.

3. Create a Music ID for `music.com.example.apple-samplecode.ControlAudio` in your developer portal.

4. Create a Key for the MusicKit service and create a developer token. For more information on this process, see [Getting Keys and Creating Tokens](https://developer.apple.com/documentation/applemusicapi/getting_keys_and_creating_tokens). 

5. Copy the developer token to the `developerToken` variable in the `MusicKitAPIController.swift` file.

6. Create a provisioning profile for `com.example.apple-samplecode.ControlAudio` and `com.example.apple-samplecode.ControlAudio.ControlAudioExtension` in your developer portal.

7. Associate the provisioning profiles with the project in Xcode signing settings.
	
	
	
