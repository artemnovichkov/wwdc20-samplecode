/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that reads NFC loyalty tag.
*/

import UIKit
import CoreNFC

class LoyaltyViewController: UITableViewController, NFCTagReaderSessionDelegate {
    
    // MARK: - Properties
    var readerSession: NFCTagReaderSession?
    @IBOutlet weak var couponText: UITextField!
    
    // MARK: - Actions
    @IBAction func scanCoupon(_ sender: Any) {
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
        
        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        readerSession?.alertMessage = "Hold your iPhone near an NFC fish tag."
        readerSession?.begin()
    }
    
    func updateWithCouponCode(_ code: String) {
        DispatchQueue.main.async {
            self.couponText.text = code
        }
    }
    
    // MARK: - Private helper functions
    func sendReadTagCommand(_ data: Data, to tag: NFCMiFareTag, _ completionHandler: @escaping (Data) -> Void) {
        if #available(iOS 14, *) {
            tag.sendMiFareCommand(commandPacket: data) { (result: Result<Data, Error>) in
                switch result {
                case .success(let response):
                    completionHandler(response)
                case .failure(let error):
                    self.readerSession?.invalidate(errorMessage: "Read tag error: \(error.localizedDescription). Please try again.")
                }
            }
        } else {
            tag.sendMiFareCommand(commandPacket: data) { (response: Data, optionalError: Error?) in
                guard let error = optionalError else {
                    completionHandler(response)
                    return
                }
                
                self.readerSession?.invalidate(errorMessage: "Read tag error: \(error.localizedDescription). Please try again.")
            }
        }
    }
    
    func readCouponCode(from tag: NFCTag) {
        guard case let .miFare(mifareTag) = tag else {
            return
        }
        
        DispatchQueue.global().async {

            // Block size of T2T tag is 4 bytes. Coupon code is stored starting
            // at block 04. Assume the maximum coupon code length is 16 bytes.
            // Coupon code data structure is as follow:
            // Block 04 => Header of the coupon. 2 bytes magic signature + 1 byte use counter + 1 byte length field.
            // Block 05 => Start of coupon code. Continues as indicated by the length field.
            
            let blockSize = 16
            // T2T Read command, returns 16 bytes in response.
            let readBlock4: [UInt8] = [0x30, 0x04]
            let magicSignature: [UInt8] = [0xFE, 0x01]
            let useCounterOffset = 2
            let lengthOffset = 3
            let headerLength = 4
            let maxCodeLength = 16
            
            self.sendReadTagCommand(Data(readBlock4), to: mifareTag) { (responseBlock4: Data) in
                // Validate magic signature and use counter
                if !responseBlock4[0...1].elementsEqual(magicSignature) || responseBlock4[useCounterOffset] < 1 {
                    self.readerSession?.invalidate(errorMessage: "No valid coupon found.")
                    return
                }
                
                let length = Int(responseBlock4[lengthOffset])
                
                if length > maxCodeLength {
                    self.readerSession?.invalidate(errorMessage: "No valid coupon found.")
                    return
                } else if length < blockSize - headerLength {
                    let code = String(bytes: responseBlock4[headerLength ... headerLength + length], encoding: .ascii)
                    self.updateWithCouponCode(code!)
                    self.readerSession?.alertMessage = "Valid coupon found."
                    self.readerSession?.invalidate()
                } else {
                    var buffer = responseBlock4[headerLength ... headerLength + length]
                    let remain = length - buffer.count
                    let readBlock8: [UInt8] = [0x30, 0x08]
                    
                    self.sendReadTagCommand(Data(readBlock8), to: mifareTag) { (responseBlock8: Data) in
                        buffer += responseBlock8[0 ... remain]
                        let code = String(bytes: buffer, encoding: .ascii)
                        self.updateWithCouponCode(code!)
                        self.readerSession?.alertMessage = "Valid coupon found."
                        self.readerSession?.invalidate()
                    }
                }
            }
        }
    }

    // MARK: - NFCTagReaderSessionDelegate
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // If necessary, you may perform additional operations on session start.
        // At this point RF polling is enabled.
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // If necessary, you may handle the error. Note the session is no longer valid.
        // You must create a new session to restart RF polling.
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        var tag: NFCTag? = nil
        
        for nfcTag in tags {
            // In this example you are searching for a MIFARE Ultralight tag (NFC Forum T2T tag platform).
            if case let .miFare(mifareTag) = nfcTag {
                if mifareTag.mifareFamily == .ultralight {
                    tag = nfcTag
                    break
                }
            }
        }
        
        if tag == nil {
            session.invalidate(errorMessage: "No valid coupon found.")
            return
        }
        
        session.connect(to: tag!) { (error: Error?) in
            if error != nil {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            self.readCouponCode(from: tag!)
        }
    }
}
