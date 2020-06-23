/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller allows to choose the video source used by the app.
     It can be either a camera or a prerecorded video file.
*/

import UIKit
import AVFoundation

class SourcePickerViewController: UIViewController {

    private let gameManager = GameManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        gameManager.stateMachine.enter(GameManager.InactiveState.self)
    }
    
    @IBAction func handleUploadVideoButton(_ sender: Any) {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        docPicker.delegate = self
        present(docPicker, animated: true)
    }
    
    @IBAction func revertToSourcePicker(_ segue: UIStoryboardSegue) {
        // This is for unwinding to this controller in storyboard.
        gameManager.reset()
    }
}

extension SourcePickerViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        gameManager.recordedVideoSource = nil
    }
    
    func  documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        gameManager.recordedVideoSource = AVAsset(url: url)
        performSegue(withIdentifier: "ShowRootControllerSegue", sender: self)
    }
}
