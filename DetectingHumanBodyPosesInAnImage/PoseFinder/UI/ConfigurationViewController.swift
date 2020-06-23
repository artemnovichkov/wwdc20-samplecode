/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a modal view that presents the PoseNet algorithm parameters
 to the user.
*/

import UIKit

protocol ConfigurationViewControllerDelegate: AnyObject {
    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateConfiguration: PoseBuilderConfiguration)

    func configurationViewController(_ viewController: ConfigurationViewController,
                                     didUpdateAlgorithm: Algorithm)
}

class ConfigurationViewController: UIViewController {
    @IBOutlet var algorithmSegmentedControl: UISegmentedControl!
    @IBOutlet var jointConfidenceThresholdLabel: UILabel!
    @IBOutlet var jointConfidenceThresholdSlider: UISlider!
    @IBOutlet var poseConfidenceThresholdLabel: UILabel!
    @IBOutlet var poseConfidenceThresholdSlider: UISlider!
    @IBOutlet var localJointSearchRadiusLabel: UILabel!
    @IBOutlet var localJointSearchRadiusSlider: UISlider!
    @IBOutlet var matchingJointMinimumDistanceLabel: UILabel!
    @IBOutlet var matchingJointMinimumDistanceSlider: UISlider!
    @IBOutlet var adjacentJointOffsetRefinementStepsLabel: UILabel!
    @IBOutlet var adjacentJointOffsetRefinementStepsSlider: UISlider!

    let jointConfidenceThresholdText = "Joint confidence threshold"
    let poseConfidenceThresholdText = "Pose confidence threshold"
    let localJointSearchRadiusText = "Local joint search radius"
    let matchingJointMinimumDistanceText = "Matching joint minimum distance"
    let adjacentJointOffsetRefinementStepsText = "Adjacent joint refinement steps"

    weak var delegate: ConfigurationViewControllerDelegate?

    var configuration: PoseBuilderConfiguration! {
        didSet {
            delegate?.configurationViewController(self, didUpdateConfiguration: configuration)
            updateUILabels()
        }
    }

    var algorithm: Algorithm = .multiple {
        didSet {
            delegate?.configurationViewController(self, didUpdateAlgorithm: algorithm)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Update UI components using values from the assigned configuration and algorithm.
        algorithmSegmentedControl.selectedSegmentIndex = algorithm == .single ? 0 : 1
        jointConfidenceThresholdSlider.value = Float(configuration.jointConfidenceThreshold)
        poseConfidenceThresholdSlider.value = Float(configuration.poseConfidenceThreshold)
        localJointSearchRadiusSlider.value = Float(configuration.localSearchRadius)
        matchingJointMinimumDistanceSlider.value = Float(configuration.matchingJointDistance)
        adjacentJointOffsetRefinementStepsSlider.value = Float(configuration.adjacentJointOffsetRefinementSteps)

        updateUILabels()
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func algorithmValueChanged(_ sender: Any) {
        algorithm = algorithmSegmentedControl.selectedSegmentIndex == 0 ? .single : .multiple
    }

    @IBAction func jointConfidenceThresholdValueChanged(_ sender: Any) {
        configuration.jointConfidenceThreshold = Double(jointConfidenceThresholdSlider.value)
    }

    @IBAction func poseConfidenceThresholdValueChanged(_ sender: Any) {
        configuration.poseConfidenceThreshold = Double(poseConfidenceThresholdSlider.value)
    }

    @IBAction func localJointSearchRadiusValueChanged(_ sender: Any) {
        configuration.localSearchRadius = Int(localJointSearchRadiusSlider.value)
    }

    @IBAction func matchingJointMinimumDistanceValueChanged(_ sender: Any) {
        configuration.matchingJointDistance = Double(matchingJointMinimumDistanceSlider.value)
    }

    @IBAction func offsetRefineStepsValueChanged(_ sender: Any) {
        configuration.adjacentJointOffsetRefinementSteps = Int(adjacentJointOffsetRefinementStepsSlider.value)
    }

    /// Update the UI labels using the `PoseBuilderConfiguration`.
    private func updateUILabels() {
        // Ensure the UI controls have been initilized
        guard jointConfidenceThresholdLabel != nil else { return }

        jointConfidenceThresholdLabel.text = jointConfidenceThresholdText
        jointConfidenceThresholdLabel.text! +=
            String(format: " (%.1f)", configuration.jointConfidenceThreshold)

        poseConfidenceThresholdLabel.text = poseConfidenceThresholdText
        poseConfidenceThresholdLabel.text! +=
            String(format: " (%.1f)", configuration.poseConfidenceThreshold)

        matchingJointMinimumDistanceLabel.text = matchingJointMinimumDistanceText
        matchingJointMinimumDistanceLabel.text! +=
            String(format: " (%.1f)", configuration.matchingJointDistance)

        localJointSearchRadiusLabel.text = localJointSearchRadiusText
        localJointSearchRadiusLabel.text! +=
        " (\(Int(configuration.localSearchRadius)))"

        adjacentJointOffsetRefinementStepsLabel.text = adjacentJointOffsetRefinementStepsText
        adjacentJointOffsetRefinementStepsLabel.text! +=
        " (\(Int(configuration.adjacentJointOffsetRefinementSteps)))"
    }
}
