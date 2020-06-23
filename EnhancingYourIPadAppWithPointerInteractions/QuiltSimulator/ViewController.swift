/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for this sample which configures bars, buttons, and actions.
*/

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, ThreadPickerViewControllerDelegate {

    @IBOutlet weak var quiltView: QuiltView?
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var removeStitchItem: UIBarButtonItem?
    @IBOutlet weak var floatingToolArea: UIView?
    @IBOutlet weak var straightLineModeButton: UIButton?

    let threadColorButton: UIButton = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        updateRulerButtonState()

        let removeAllStitches =
                UIAction(title: "Remove All Stitches",
                         image: nil,
                         identifier: nil,
                         discoverabilityTitle: nil,
                         attributes: .destructive,
                         state: .off) { (action) in
                    self.quiltView?.ripAllStitches()
                }
        let removeMenu =
                UIMenu(title: "Start Over?",
                       image: nil,
                       identifier: nil,
                       options: .destructive,
                       children: [removeAllStitches])
        removeStitchItem?.menu = removeMenu

        scrollView?.maximumZoomScale = 4.0
        threadColorButton.addTarget(self, action: #selector(threadColorAction), for: .touchUpInside)
        let spoolImage = UIImage(named: "spool")?.withRenderingMode(.alwaysTemplate)
        threadColorButton.setImage(spoolImage, for: .normal)
        threadColorButton.tintColor = quiltView?.stitchColor
        threadColorButton.translatesAutoresizingMaskIntoConstraints = false
        threadColorButton.widthAnchor.constraint(equalTo: threadColorButton.heightAnchor).isActive = true
        threadColorButton.heightAnchor.constraint(equalToConstant: 33).isActive = true
        updateThreadButtonTintColor()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: threadColorButton)

        // Enable Pointer Interaction on the button.
        straightLineModeButton?.isPointerInteractionEnabled = true
        
        // Setup pointerStyleProvider to expand hover effect shape to more appropriate size.
        straightLineModeButton?.pointerStyleProvider = { button, proposedEffect, proposedShape -> UIPointerStyle? in
            // Rect in proposedEffect’s container’s coordinate space
            var rect = button.bounds.insetBy(dx: -12.0, dy: -14.0)
            rect = button.convert(rect, to: proposedEffect.preview.target.container)
            return UIPointerStyle(effect: proposedEffect, shape: .roundedRect(rect))
        }
        
        // Add Lift Effect to Thread Color Button.
        threadColorButton.pointerStyleProvider = { button, proposedEffect, proposedShape -> UIPointerStyle? in
            let parameters = UIPreviewParameters()
            let shapePath = UIBezierPath(roundedRect: button.bounds, cornerRadius: 4)
            parameters.shadowPath = shapePath
            let preview = UITargetedPreview(view: proposedEffect.preview.view, parameters: parameters, target: proposedEffect.preview.target)
            return UIPointerStyle(effect: .lift(preview), shape: .path(shapePath))
        }
    }

    @objc
    func threadColorAction(sender: UIButton, forEvent event: UIEvent) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let threadPicker = storyboard.instantiateViewController(identifier: "ThreadPickerViewController") as ThreadPickerViewController
        threadPicker.modalPresentationStyle = .popover
        threadPicker.delegate = self
        if let popoverController = threadPicker.popoverPresentationController {
            popoverController.sourceView = sender
        }
        self.present(threadPicker, animated: true, completion: nil)
    }

    @IBAction func rulerButtonAction(sender: UIButton, forEvent event: UIEvent) {
        if let value = quiltView?.useStraightLineStitch {
            let newValue = !value
            quiltView?.useStraightLineStitch = newValue
            updateRulerButtonState()
        }
    }

    func updateRulerButtonState() {
        if let value = quiltView?.useStraightLineStitch {
            if value {
                straightLineModeButton?.setImage(UIImage(systemName: "ruler.fill"), for: .normal)
            } else {
                straightLineModeButton?.setImage(UIImage(systemName: "ruler"), for: .normal)
            }
        }
    }

    @IBAction func removeStitch(sender: UIBarButtonItem, forEvent event: UIEvent) {
        quiltView?.ripLastStitch()
    }

    // MARK: - ThreadPickerViewControllerDelegate
    
    func threadPickerDidPickColor(_ threadPicker: ThreadPickerViewController, color: UIColor) {
        quiltView?.stitchColor = color
        updateThreadButtonTintColor()
        threadPicker.dismiss(animated: true, completion: nil)
    }

    func updateThreadButtonTintColor() {
        if let color = quiltView?.stitchColor {
            threadColorButton.tintColor = color
        }
    }

    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return quiltView
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let roundOverlay = floatingToolArea {
            roundOverlay.layer.cornerRadius = (roundOverlay.bounds.size.width / 2.0)
            roundOverlay.layer.borderWidth = 0.5
            roundOverlay.layer.borderColor = UIColor.separator.cgColor
            roundOverlay.backgroundColor = UIColor.secondarySystemBackground
        }
    }

}
