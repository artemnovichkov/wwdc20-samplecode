/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the settings popover.
*/

import UIKit

let practiceScales: [CGFloat] = [0.7, 1.0, 1.25, 1.5, 2.0]
let practiceSpeeds: [CGFloat] = [0.5, 0.75, 1.0, 1.5, 2.0]
let difficulties: [CGFloat] = [20, 10, 7, 5, 4]

extension Collection where Element == CGFloat {
    // A floating point safe version of firstIndex.
    func firstIndexAlmostEqual(_ value: CGFloat) -> Index? {
        firstIndex { abs($0 - value) < 0.1 }
    }
}

class SettingsViewController: UIViewController {
    @IBOutlet weak var practiceScaleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var animationSpeedSegmentedControl: UISegmentedControl!
    @IBOutlet weak var difficultySegmentedControl: UISegmentedControl!
    
    var practiceViewController: PracticeViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let practiceViewController = practiceViewController {
            practiceScaleSegmentedControl.selectedSegmentIndex = practiceScales.firstIndexAlmostEqual(practiceViewController.practiceScale) ?? 2
            animationSpeedSegmentedControl.selectedSegmentIndex = practiceSpeeds.firstIndexAlmostEqual(practiceViewController.animationSpeed) ?? 2
            difficultySegmentedControl.selectedSegmentIndex = difficulties.firstIndexAlmostEqual(practiceViewController.difficulty) ?? 2
        }
    }
    
    @IBAction func practiceScaleChanged(_ sender: Any) {
        practiceViewController?.practiceScale = practiceScales[practiceScaleSegmentedControl.selectedSegmentIndex]
    }
    
    @IBAction func practiceSpeedChanged(_ sender: Any) {
        practiceViewController?.animationSpeed = practiceSpeeds[animationSpeedSegmentedControl.selectedSegmentIndex]
    }
    
    @IBAction func difficultyChanged(_ sender: Any) {
        practiceViewController?.difficulty = difficulties[difficultySegmentedControl.selectedSegmentIndex]
    }
}
