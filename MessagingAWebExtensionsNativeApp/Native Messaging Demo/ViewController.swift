/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Controls the extension's parent app.
*/
import Cocoa
import SafariServices.SFSafariApplication
import SafariServices.SFSafariExtensionManager
import os.log

let appName = "Native Messaging Demo"
let extensionBundleIdentifier = "com.example.apple-samplecode.Native-Messaging-Demo-Extension"

class ViewController: NSViewController {

    @IBOutlet var appNameLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLabel.stringValue = appName
        
        // Check the status of the extension in Safari and update the UI.
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else {
                var errorMessage: String = "Error: unable to determine state of the extension"

                if let errorDetail = error as NSError?, errorDetail.code == 1 {
                    errorMessage = "Couldn’t find the Native Messaging Demo extension. Are you running macOS 10.16+, or macOS 10.14+ with Safari 14+?"
                }

                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Check Version"
                    alert.informativeText = errorMessage
                    alert.beginSheetModal(for: self.view.window!) { (response) in }
                    
                    self.appNameLabel.stringValue = errorMessage
                }
                return
            }

            DispatchQueue.main.async {
                if state.isEnabled {
                    self.appNameLabel.stringValue = "\(appName)'s extension is currently on."
                } else {
                    self.appNameLabel.stringValue = "\(appName)'s extension is currently off. You can turn it on in Safari Extensions preferences."
                }
            }
        }
    }
    
    @IBAction func sendMessageToExtension(_ sender: AnyObject?) {
        // Send a message to the background page running in Safari.
        SFSafariApplication.dispatchMessage(withName: "Hello from App", toExtensionWithIdentifier: extensionBundleIdentifier,
                                            userInfo: ["AdditionalInformation": "Goes Here"], completionHandler: { (error) -> Void in
            os_log(.default, "Dispatching message to the extension finished")
        })
    }
}
