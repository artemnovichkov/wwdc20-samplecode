/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Controls the extension's parent app.
*/
import Cocoa
import SafariServices.SFSafariApplication
import SafariServices.SFSafariExtensionManager

let appName = "Sea Creator"
let extensionBundleIdentifier = "com.example.apple-samplecode.Sea-Creator-Extension"

class ViewController: NSViewController {

    @IBOutlet var appNameLabel: NSTextField!
    @IBOutlet var replacementCountLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLabel.stringValue = appName
        
        // Check the status of the extension in Safari and update the UI.
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else {
                var errorMessage: String = "Error: unable to determine state of the extension"
                
                if let errorDetail = error as NSError?, errorDetail.code == 1 {
                    errorMessage = "Couldn’t find the Sea Creator extension. Are you running macOS 10.16+, or macOS 10.14+ with Safari 14+?"
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
    
    @IBAction func openSafariExtensionPreferences(_ sender: AnyObject?) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            guard error == nil else {
                var errorMessage: String = "Error: unable to show preferences for the extension."
                
                if let errorDetail = error as NSError?, errorDetail.code == 1 {
                    errorMessage = "Couldn’t find the Sea Creator extension. Are you running macOS 10.16+, or macOS 10.14+ with Safari 14+?"
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
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    @IBAction func updateReplacementStats(_ sender: AnyObject?) {
        // Read from UserDefaults and set the text in the app's UI.
        let defaults = UserDefaults(suiteName: "com.example.apple-samplecode.Sea-Creator.group")
        let replacementCount = (defaults?.integer(forKey: "WordReplacementCount")) ?? 0
        replacementCountLabel.stringValue = "You've replaced \(replacementCount) animals with emoji."
    }

}
