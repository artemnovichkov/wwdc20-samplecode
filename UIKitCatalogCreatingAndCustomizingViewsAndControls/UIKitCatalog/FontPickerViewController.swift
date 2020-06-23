/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UIFontPickerViewController`.
*/

import UIKit

class FontPickerViewController: UIViewController, UIFontPickerViewControllerDelegate {

    // MARK: - Properties

    var fontPicker: UIFontPickerViewController!
    @IBOutlet var fontLabel: UILabel!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureFontPicker()
    }

    func configureFontPicker() {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true
        configuration.displayUsingSystemFont = false
        configuration.filteredTraits = [.classModernSerifs]

        fontPicker = UIFontPickerViewController(configuration: configuration)
        fontPicker.delegate = self
    }

    @IBAction func presentFontPicker(_: AnyObject) {
        present(fontPicker, animated: true)
    }
    
    // MARK: - UIFontPickerViewControllerDelegate

    func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
        //..
    }

    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let fontDescriptor = viewController.selectedFontDescriptor else { return }
        let font = UIFont(descriptor: fontDescriptor, size: 48.0)
        fontLabel.font = font
        fontLabel.text = NSLocalizedString("SampleFontTitle", comment: "")
        
        Swift.debugPrint("Chosen font: \(font)")
    }
    
}
