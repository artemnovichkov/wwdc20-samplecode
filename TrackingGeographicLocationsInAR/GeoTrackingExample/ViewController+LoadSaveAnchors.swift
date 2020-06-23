/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller extension for loading and saving geo anchors.
 
 To demonstrate the usefulness of user-created navigations, the sample
 app allows the user to save anchor collections they've created, load
 prior collections, or load any collections that others have shared.
*/

import UIKit
import ARKit

let GPXFileExtension = "gpx"

extension ViewController: GPXParserDelegate {
    
    func showGPXFiles() {
        // Load objects in the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            alertUser(withTitle: "Couldn't list files", message: "Unable to access the documents folder.")
            return
        }
        
        var gpxURLs: [URL] = []
        
        // Retrieve the URLs of all GPX files sorted by name
        if let urlsInDocumentsDirectory = try? FileManager.default
            .contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            .filter({ $0.pathExtension.lowercased() == GPXFileExtension })
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            gpxURLs.append(contentsOf: urlsInDocumentsDirectory)
        }
        
        guard !gpxURLs.isEmpty else {
            alertUser(withTitle: "No GPX files found", message: "Unable to find any saved geo anchors.")
            return
        }
        
        // Display the list of files
        var alertActions = gpxURLs.map({ (url) in
            return UIAlertAction(title: url.lastPathComponent, style: .default) { _ in
                self.parseGPXFile(with: url)
            }
        })
        
        // Action to cancel the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertActions.append(cancelAction)
        
        alertUser(withTitle: "Choose GPX file", message: "", actions: alertActions)
    }
    
    func saveAnchorsAsGPXFile(_ anchors: [ARGeoAnchor]) {
        // Display an alert to enter a file name
        let alert = UIAlertController(title: "GPX File Name", message: "File name to save the anchors to.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYYMMdd-hhmmss"

            textField.text = "GeoAnchors-\(dateFormatter.string(from: Date()))"
            textField.clearsOnInsertion = true
        }
        
        // Action to save the file to disk
        let saveAction = UIAlertAction(title: "Save to documents", style: .default) { _ in
            guard let documentsDirectory = try? FileManager.default.url(for: .documentDirectory,
                                                                        in: .userDomainMask, appropriateFor: nil, create: true) else {
                self.alertUser(withTitle: "Write Failed", message: "Unable to access the documents folder")
                return
            }

            let fileName = alert.textFields?.first?.text ?? "Untitled"
            let url = documentsDirectory.appendingPathComponent(fileName).appendingPathExtension(GPXFileExtension)
            
            do {
                try GPXExporter.shared.exportGeoAnchors(anchors, toFileWithURL: url)
                self.showToast("Saved geo anchor(s)")
            } catch {
                self.showToast("Unable to save geo anchor(s)")
            }
        }
        
        // Action to share the file via the system share sheet
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            let fileName = alert.textFields?.first?.text ?? "Untitled"
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(fileName)
                .appendingPathExtension(GPXFileExtension)
            do {
                try GPXExporter.shared.exportGeoAnchors(anchors, toFileWithURL: tempURL)
                let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = nil
                self.present(activityViewController, animated: true)
            } catch {
                self.showToast("Unable to export geo anchor(s)")
            }
        }
        
        // Action to cancel the export
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(shareAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    func parseGPXFile(with url: URL) {
        guard let parser = GPXParser(contentsOf: url) else {
            showToast("Unable to open GPX file.")
            return
        }
        
        parser.delegate = self
        parser.parse()
    }
    
    // MARK: - GPXParserDelegate
    
    func parser(_ parser: GPXParser, didFinishParsingFileWithAnchors anchors: [ARGeoAnchor]) {
        
        // Don't add geo anchors if geo tracking isn't sure yet where the user is.
        guard isGeoTrackingLocalized else {
            alertUser(withTitle: "Cannot add geo anchor(s)", message: "Unable to add geo anchor(s) because geo tracking has not yet localized.")
            return
        }
        
        if anchors.isEmpty {
            alertUser(withTitle: "No anchors added", message: "GPX file does not contain anchors or is invalid.")
            return
        }
        
        for anchor in anchors {
            addGeoAnchor(anchor)
        }
        
        showToast("\(anchors.count) anchor(s) added.")
    }
}
