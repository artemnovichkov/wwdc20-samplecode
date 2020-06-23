/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that reads NFC fish tag.
*/

import UIKit
import CoreNFC
import os

class ScanViewController: UITableViewController, NFCTagReaderSessionDelegate {

    // MARK: - Properties
    var readerSession: NFCTagReaderSession?
    
    @IBOutlet weak var kindText: UITextField!
    @IBOutlet weak var dateText: UITextField!
    @IBOutlet weak var priceText: UITextField!
    @IBOutlet weak var infoText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    @IBAction func scanTag(_ sender: Any) {
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        readerSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self, queue: nil)
        readerSession?.alertMessage = "Hold your iPhone near an NFC fish tag."
        readerSession?.begin()
    }
    
    // MARK: - Private helper functions
    func tagRemovalDetect(_ tag: NFCTag) {
        self.readerSession?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                
                os_log("Restart polling.")
                
                self.readerSession?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }
    
    func getDate(from value: String?) -> String? {
        guard let dateString = value else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateStyle = .medium
        outputDateFormatter.timeStyle = .none
        
        return outputDateFormatter.string(from: dateFormatter.date(from: dateString)!)
    }
    
    func getPrice(from value: String?) -> String? {
        guard let priceString = value else {
            return nil
        }
        
        return String("$\(priceString.prefix(priceString.count - 2)).\(priceString.suffix(2))")
    }
    
    func updateWithNDEFMessage(_ message: NFCNDEFMessage) -> Bool {
        // UI elements are updated based on the received NDEF message.
        let urls: [URLComponents] = message.records.compactMap { (payload: NFCNDEFPayload) -> URLComponents? in
            // Search for URL record with matching domain host and scheme.
            if let url = payload.wellKnownTypeURIPayload() {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if components?.host == "fishtagcreator.example.com" && components?.scheme == "https" {
                    return components
                }
            }
            return nil
        }
        
        // Valid tag should only contain 1 URL and contain multiple query items.
        guard urls.count == 1,
            let items = urls.first?.queryItems else {
            return false
        }
        
        // Get the optional info text from the text payload.
        var additionInfo: String? = nil

        for payload in message.records {
            (additionInfo, _) = payload.wellKnownTypeTextPayload()
            
            if additionInfo != nil {
                break
            }
        }
        
        DispatchQueue.main.async {
            self.infoText.text = additionInfo
            
            for item in items {
                switch item.name {
                case "date":
                    self.dateText.text = self.getDate(from: item.value)
                case "price":
                    self.priceText.text = self.getPrice(from: item.value)
                case "kind":
                    self.kindText.text = item.value
                default:
                    break
                }
            }
        }
        
        return true
    }
    
    // MARK: - NFCTagReaderSessionDelegate
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // If necessary, you may perform additional operations on session start.
        // At this point RF polling is enabled.
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // If necessary, you may handle the error. Note session is no longer valid.
        // You must create a new session to restart RF polling.
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            session.alertMessage = "More than 1 tags was found. Please present only 1 tag."
            self.tagRemovalDetect(tags.first!)
            return
        }
        
        var ndefTag: NFCNDEFTag
        
        switch tags.first! {
        case let .iso7816(tag):
            ndefTag = tag
        case let .feliCa(tag):
            ndefTag = tag
        case let .iso15693(tag):
            ndefTag = tag
        case let .miFare(tag):
            ndefTag = tag
        @unknown default:
            session.invalidate(errorMessage: "Tag not valid.")
            return
        }
        
        session.connect(to: tags.first!) { (error: Error?) in
            if error != nil {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            
            ndefTag.queryNDEFStatus() { (status: NFCNDEFStatus, _, error: Error?) in
                if status == .notSupported {
                    session.invalidate(errorMessage: "Tag not valid.")
                    return
                }
                ndefTag.readNDEF() { (message: NFCNDEFMessage?, error: Error?) in
                    if error != nil || message == nil {
                        session.invalidate(errorMessage: "Read error. Please try again.")
                        return
                    }
                    
                    if self.updateWithNDEFMessage(message!) {
                        session.alertMessage = "Tag read success."
                        session.invalidate()
                        return
                    }
                    
                    session.invalidate(errorMessage: "Tag not valid.")
                }
            }
        }
    }
}

