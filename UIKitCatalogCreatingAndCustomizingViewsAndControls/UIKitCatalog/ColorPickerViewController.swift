/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UIColorPickerViewController`.
*/

import UIKit

class ColorPickerViewController: UIViewController, UIColorPickerViewControllerDelegate {

    // MARK: - Properties

    var colorPicker: UIColorPickerViewController!
    @IBOutlet var colorView: UIView!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureColorPicker()
    }

    func configureColorPicker() {
        colorPicker = UIColorPickerViewController()
        colorPicker.supportsAlpha = true
        colorPicker.selectedColor = UIColor.blue
        colorPicker.delegate = self
    }

    @IBAction func presentColorPicker(_: AnyObject) {
        present(colorPicker, animated: true, completion: nil)
    }
    
    // MARK: - UIColorPickerViewControllerDelegate
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        // User has chosen a color.
        let chosenColor = viewController.selectedColor
        colorView.backgroundColor = chosenColor
        
        Swift.debugPrint("\(chosenColor)")
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        /** In presentations (except popovers) the color picker shows a close button. If the close button is tapped,
            the view controller is dismissed and `colorPickerViewControllerDidFinish:` is called. Can be used to
            animate alongside the dismissal.
        */
    }

}

extension UIColor {
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard let components = self.cgColor.components else { return nil }

        return (
            red: components[0],
            green: components[1],
            blue: components[2],
            alpha: components[3]
        )
    }
}
