/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UICollectionViewController subclass for picking a thread color by displaying a grid of adjacent colored circles with the Lift pointer effect.
*/

import UIKit

protocol ThreadPickerViewControllerDelegate: NSObjectProtocol {

    func threadPickerDidPickColor(_ threadPicker: ThreadPickerViewController, color: UIColor)
}

class ThreadPickerViewController: UICollectionViewController {

    weak var delegate: ThreadPickerViewControllerDelegate?

    let colors = [UIColor(named: "GreyThread"),
                  UIColor(named: "BrownThread"),
                  UIColor(named: "PurpleThread"),
                  UIColor(named: "BlueThread"),
                  UIColor(named: "GreenThread"),
                  UIColor(named: "YellowThread"),
                  UIColor(named: "OrangeThread"),
                  UIColor(named: "RedThread"),
                  UIColor(named: "PinkThread")]

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as? ThreadCell
            else { preconditionFailure("Failed to load collection view cell") }
        
        cell.swatch?.backgroundColor = colors[indexPath.item]
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let newColor = colors[indexPath.item] {
            delegate?.threadPickerDidPickColor(self, color: newColor)
        }
    }
    
}

class ThreadCell: UICollectionViewCell, UIPointerInteractionDelegate {
    @IBOutlet weak var swatch: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    func sharedInit() {
        let pointerInteraction = UIPointerInteraction(delegate: self)
        self.addInteraction(pointerInteraction)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.swatch?.layer.cornerRadius = (self.swatch?.bounds.size.height ?? 0) / 2.0
    }

    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        if let circleView = swatch {
            let parameters = UIPreviewParameters()
            let shapePath = UIBezierPath(roundedRect: circleView.bounds, cornerRadius: circleView.bounds.size.height / 2.0)
            parameters.shadowPath = shapePath
            let preview = UITargetedPreview(view: circleView, parameters: parameters)
            return UIPointerStyle(effect: .lift(preview), shape: .path(shapePath))
        } else {
            return nil
        }
    }

}
