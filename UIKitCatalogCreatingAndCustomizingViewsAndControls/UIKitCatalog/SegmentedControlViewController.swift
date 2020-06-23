/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UISegmentedControl`.
*/

import UIKit

class SegmentedControlViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tintedSegmentedControl: UISegmentedControl!
    @IBOutlet weak var customSegmentsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var customBackgroundSegmentedControl: UISegmentedControl!
    @IBOutlet weak var actionBasedSegmentedControl: UISegmentedControl!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSegmentedControl()
        configureTintedSegmentedControl()
        configureCustomSegmentsSegmentedControl()
        configureCustomBackgroundSegmentedControl()
        configureActionBasedSegmentedControl()
    }

    // MARK: - Configuration

    func configureDefaultSegmentedControl() {
        // As a demonstration, disable the first segment.
        defaultSegmentedControl.setEnabled(false, forSegmentAt: 0)

        defaultSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }

    func configureTintedSegmentedControl() {
        // Use a dynamic tinted color (separate one for Light Appearance and separate one for Dark Appearance).
        tintedSegmentedControl.selectedSegmentTintColor = UIColor(named: "tinted_segmented_control")!

        tintedSegmentedControl.selectedSegmentIndex = 1

        tintedSegmentedControl.addTarget(self, action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)), for: .valueChanged)
    }
    
    func configureCustomSegmentsSegmentedControl() {
        let airplaneImage = UIImage(systemName: "airplane")
        airplaneImage?.accessibilityLabel = NSLocalizedString("Airplane", comment: "")
        customSegmentsSegmentedControl.setImage(airplaneImage, forSegmentAt: 0)
        
        let giftImage = UIImage(systemName: "gift")
        giftImage?.accessibilityLabel = NSLocalizedString("Gift", comment: "")
        customSegmentsSegmentedControl.setImage(giftImage, forSegmentAt: 1)
        
        let burstImage = UIImage(systemName: "burst")
        burstImage?.accessibilityLabel = NSLocalizedString("Burst", comment: "")
        customSegmentsSegmentedControl.setImage(burstImage, forSegmentAt: 2)
        
        customSegmentsSegmentedControl.selectedSegmentIndex = 0

        customSegmentsSegmentedControl.addTarget(self,
                                                 action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)),
                                                 for: .valueChanged)
    }
    
    func configureCustomBackgroundSegmentedControl() {
        customBackgroundSegmentedControl.selectedSegmentIndex = 2

        // Set the background images for each control state.
        let normalSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background")
        customBackgroundSegmentedControl.setBackgroundImage(normalSegmentBackgroundImage, for: .normal, barMetrics: .default)

        let disabledSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_disabled")
        customBackgroundSegmentedControl.setBackgroundImage(disabledSegmentBackgroundImage, for: .disabled, barMetrics: .default)

        let highlightedSegmentBackgroundImage = UIImage(named: "stepper_and_segment_background_highlighted")
        customBackgroundSegmentedControl.setBackgroundImage(highlightedSegmentBackgroundImage, for: .highlighted, barMetrics: .default)

        // Set the divider image.
        let segmentDividerImage = UIImage(named: "stepper_and_segment_divider")
        customBackgroundSegmentedControl.setDividerImage(segmentDividerImage,
                                                         forLeftSegmentState: .normal,
                                                         rightSegmentState: .normal,
                                                         barMetrics: .default)

        // Create a font to use for the attributed title, for both normal and highlighted states.
        let captionFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1)
        let font = UIFont(descriptor: captionFontDescriptor, size: 0)

        let normalTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.systemPurple,
            NSAttributedString.Key.font: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)

        let highlightedTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.systemGreen,
            NSAttributedString.Key.font: font
        ]
        customBackgroundSegmentedControl.setTitleTextAttributes(highlightedTextAttributes, for: .highlighted)

        customBackgroundSegmentedControl.addTarget(self,
                                                   action: #selector(SegmentedControlViewController.selectedSegmentDidChange(_:)),
                                                   for: .valueChanged)
    }

    func configureActionBasedSegmentedControl() {
        actionBasedSegmentedControl.selectedSegmentIndex = 0
        let firstAction =
            UIAction(title: NSLocalizedString("CheckTitle", comment: "")) { action in
                Swift.debugPrint("Segment Action '\(action.title)'")
            }
        actionBasedSegmentedControl.setAction(firstAction, forSegmentAt: 0)
        let secondAction =
            UIAction(title: NSLocalizedString("SearchTitle", comment: "")) { action in
                Swift.debugPrint("Segment Action '\(action.title)'")
            }
        actionBasedSegmentedControl.setAction(secondAction, forSegmentAt: 1)
        let thirdAction =
            UIAction(title: NSLocalizedString("ToolsTitle", comment: "")) { action in
                Swift.debugPrint("Segment Action '\(action.title)'")
            }
        actionBasedSegmentedControl.setAction(thirdAction, forSegmentAt: 2)
    }
        
    // MARK: - Actions

    @objc
    func selectedSegmentDidChange(_ segmentedControl: UISegmentedControl) {
        print("The selected segment changed for: \(segmentedControl).")
    }
}
