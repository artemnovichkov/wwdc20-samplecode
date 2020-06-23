/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The thumbnail cell for showing thumbnails in ThumbnailCollectionViewController.
*/

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    /// Set up the view initially.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Give the view a shadow.
        imageView.layer.shadowPath = UIBezierPath(rect: imageView.bounds).cgPath
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        imageView.clipsToBounds = false
    }
}
