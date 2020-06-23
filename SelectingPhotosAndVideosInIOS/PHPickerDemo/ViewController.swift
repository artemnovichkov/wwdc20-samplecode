/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller object.
*/

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView! {
        didSet {
            livePhotoView.contentMode = .scaleAspectFit
        }
    }
    
    private var itemProviders = [NSItemProvider]()
    private var itemProvidersIterator: IndexingIterator<[NSItemProvider]>?
    private var currentItemProvider: NSItemProvider?
    
    @IBAction func presentPickerForImagesIncludingLivePhotos(_ sender: Any) {
        presentPicker(filter: PHPickerFilter.images)
    }

    @IBAction func presentPickerForLivePhotosOnly(_ sender: Any) {
        presentPicker(filter: PHPickerFilter.livePhotos)
    }
    
    private func presentPicker(filter: PHPickerFilter) {
        var configuration = PHPickerConfiguration()
        configuration.filter = filter
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        displayNextImage()
    }
    
}

private extension ViewController {
    func displayNextImage() {
        guard let itemProvider = itemProvidersIterator?.next() else { return }
        currentItemProvider = itemProvider
        if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                DispatchQueue.main.async {
                    guard let self = self, self.currentItemProvider == itemProvider else { return }
                    if let livePhoto = livePhoto as? PHLivePhoto {
                        self.display(livePhoto: livePhoto)
                    } else {
                        self.display(image: UIImage(systemName: "exclamationmark.circle"))
                        print("Couldn't load live photo with error: \(error?.localizedDescription ?? "unknown error")")
                   }
                }
            }
        } else if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    guard let self = self, self.currentItemProvider == itemProvider else { return }
                    if let image = image as? UIImage {
                        self.display(image: image)
                    } else {
                        self.display(image: UIImage(systemName: "exclamationmark.circle"))
                        print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        } else {
            print("Unsupported item provider: \(itemProvider)")
        }
    }
    
    func display(livePhoto: PHLivePhoto? = nil, image: UIImage? = nil) {
        livePhotoView.livePhoto = livePhoto
        livePhotoView.isHidden = livePhoto == nil
        imageView.image = image
        imageView.isHidden = image == nil
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        itemProviders = results.map(\.itemProvider)
        itemProvidersIterator = itemProviders.makeIterator()
        displayNextImage()
    }
    
}
