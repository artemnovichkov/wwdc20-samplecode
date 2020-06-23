/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ThumbnailCollectionViewController` shows a set of thumbnails of all drawings.
*/

import UIKit
import PencilKit

class ThumbnailCollectionViewController: UICollectionViewController, DataModelControllerObserver {
    
    /// Data model for the drawings displayed by this view controller.
    var dataModelController = DataModelController()
    
    // MARK: View Life Cycle
    
    /// Set up the view initially.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Inform the data model of the current thumbnail traits.
        dataModelController.thumbnailTraitCollection = traitCollection
        
        // Observe changes to the data model.
        dataModelController.observers.append(self)
    }
    
    /// Inform the data model of the current thumbnail traits.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        dataModelController.thumbnailTraitCollection = traitCollection
    }
    
    // MARK: Data Model Observer
    
    func dataModelChanged() {
        collectionView.reloadData()
    }
    
    // MARK: Actions
    
    /// Action method: Create a new drawing.
    @IBAction func newDrawing(_ sender: Any) {
        dataModelController.newDrawing()
    }
    
    // MARK: Collection View Data Source
    
    /// Data source method: Number of sections.
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /// Data source method: Number of items in each section.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModelController.drawings.count
    }
    
    /// Data source method: The view for each cell.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get a cell view with the correct identifier.
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ThumbnailCell",
            for: indexPath) as? ThumbnailCollectionViewCell
            else {
                fatalError("Unexpected cell type.")
        }
        
        // Set the thumbnail image, if available.
        if let index = indexPath.last, index < dataModelController.thumbnails.count {
            cell.imageView.image = dataModelController.thumbnails[index]
        }
        
        return cell
    }
    
    // MARK: Collection View Delegate
    
    /// Delegate method: Display the drawing for a cell that was tapped.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Create the drawing.
        guard let drawingViewController = storyboard?.instantiateViewController(withIdentifier: "DrawingViewController") as? DrawingViewController,
            let navigationController = navigationController else {
                return
        }
        
        // Transition to the drawing view controller.
        drawingViewController.dataModelController = dataModelController
        drawingViewController.drawingIndex = indexPath.last!
        navigationController.pushViewController(drawingViewController, animated: true)
    }
}
