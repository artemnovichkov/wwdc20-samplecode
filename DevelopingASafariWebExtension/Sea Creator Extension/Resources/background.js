/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Script that makes up the extension's background page.
*/
// Send a message from the Safari Web Extension to the containing app extension.
browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type == "Word replaced") {
        browser.runtime.sendNativeMessage({ message: "Word replaced" });
    }
});

