/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Script that makes up the extension's background page.
*/
// Send a message to the native app extension from the background page.
browser.runtime.sendNativeMessage("application.id", {message: "Hello from background page"}, function(response) {
    console.log("Received sendNativeMessage response:");
    console.log(response);
});

// Set up a connection to receive messages from the native app.
let port = browser.runtime.connectNative("application.id");
port.postMessage("Hello from JavaScript Port");
port.onMessage.addListener(function(message) {
    console.log("Received native port message:");
    console.log(message);
});
port.onDisconnect.addListener(function(disconnectedPort) {
    console.log("Received native port disconnect:");
    console.log(disconnectedPort);
});

