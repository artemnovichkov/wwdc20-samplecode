/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that creates an NFC tag for fish.
*/

import UIKit
import CoreNFC
import os

class MainViewController: UITableViewController, UINavigationControllerDelegate, NFCNDEFReaderSessionDelegate {
 
    // MARK: - Properties
    let fishKinds = [String](arrayLiteral: "Creative Salmon", "Amazing Tuna", "Dancing Mahi-Mahi", "Incredible Bass")
    let priceBCD = [String](arrayLiteral: "0599", "1099", "1599") // BCD encoded price
    var readerSession: NFCNDEFReaderSession?
    var ndefMessage: NFCNDEFMessage?
 
    @IBOutlet weak var productPrice: UISegmentedControl!
    @IBOutlet weak var productDate: UIDatePicker!
    @IBOutlet weak var productKind: UIPickerView!
        
    // MARK: - Actions
    @IBAction func writeTag(_ sender: Any) {
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
        
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        readerSession?.alertMessage = "Hold your iPhone near a writable NFC tag to update."
        readerSession?.begin()
    }
    
    // MARK: - Private functions
    func createURLPayload() -> NFCNDEFPayload? {
        var dateString: String?
        var priceString: String?
        var kindString: String?
        
        DispatchQueue.main.sync {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            dateString = dateFormatter.string(from: self.productDate.date)
            
            kindString = fishKinds[productKind.selectedRow(inComponent: 0)]
            
            priceString = priceBCD[productPrice.selectedSegmentIndex]
        }
        
        var urlComponent = URLComponents(string: "https://fishtagcreator.example.com/")
        
        urlComponent?.queryItems = [URLQueryItem(name: "date", value: dateString),
                                    URLQueryItem(name: "kind", value: kindString),
                                    URLQueryItem(name: "price", value: priceString)]
        
        os_log("url: %@", (urlComponent?.string)!)
        
        return NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent?.url)!)
    }
    
    func tagRemovalDetect(_ tag: NFCNDEFTag) {
        // In the tag removal procedure, you connect to the tag and query for
        // its availability. You restart RF polling when the tag becomes
        // unavailable; otherwise, wait for certain period of time and repeat
        // availability checking.
        self.readerSession?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                
                os_log("Restart polling")
                
                self.readerSession?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: "Brought to you by the Great Fish Company",
            locale: Locale(identifier: "En")
        )
        let urlPayload = self.createURLPayload()
        ndefMessage = NFCNDEFMessage(records: [urlPayload!, textPayload!])
        os_log("MessageSize=%d", ndefMessage!.length)
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // If necessary, you may handle the error. Note session is no longer valid.
        // You must create a new session to restart RF polling.
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Do not add code in this function. This method isn't called
        // when you provide `reader(_:didDetect:)`.
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            session.alertMessage = "More than 1 tags found. Please present only 1 tag."
            self.tagRemovalDetect(tags.first!)
            return
        }
        
        // You connect to the desired tag.
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            if error != nil {
                session.restartPolling()
                return
            }
            
            // You then query the NDEF status of tag.
            tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                    return
                }
                
                if status == .readOnly {
                    session.invalidate(errorMessage: "Tag is not writable.")
                } else if status == .readWrite {
                    if self.ndefMessage!.length > capacity {
                        session.invalidate(errorMessage: "Tag capacity is too small.  Minimum size requirement is \(self.ndefMessage!.length) bytes.")
                        return
                    }
                    
                    // When a tag is read-writable and has sufficient capacity,
                    // write an NDEF message to it.
                    tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
                        if error != nil {
                            session.invalidate(errorMessage: "Update tag failed. Please try again.")
                        } else {
                            session.alertMessage = "Update success!"
                            session.invalidate()
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Tag is not NDEF formatted.")
                }
            }
        }
    }
}

