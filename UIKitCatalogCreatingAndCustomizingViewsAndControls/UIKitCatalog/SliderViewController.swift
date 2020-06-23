/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UISlider`.
*/

import UIKit

class SliderViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var defaultSlider: UISlider!
    @IBOutlet weak var tintedSlider: UISlider!
    @IBOutlet weak var customSlider: UISlider!
    @IBOutlet weak var minMaxImageSlider: UISlider!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureDefaultSlider()
        configureTintedSlider()
        configureCustomSlider()
        configureMinMaxImageSlider()
    }

    // MARK: - Configuration

    func configureDefaultSlider() {
        defaultSlider.minimumValue = 0
        defaultSlider.maximumValue = 100
        defaultSlider.value = 42
        defaultSlider.isContinuous = true

        defaultSlider.addTarget(self, action: #selector(SliderViewController.sliderValueDidChange(_:)), for: .valueChanged)
    }

    func configureTintedSlider() {
        tintedSlider.minimumTrackTintColor = UIColor.systemBlue
        tintedSlider.maximumTrackTintColor = UIColor.systemPurple

        tintedSlider.addTarget(self, action: #selector(SliderViewController.sliderValueDidChange(_:)), for: .valueChanged)
    }

    func configureCustomSlider() {
        let leftTrackImage = UIImage(named: "slider_blue_track")
        customSlider.setMinimumTrackImage(leftTrackImage, for: .normal)

        let rightTrackImage = UIImage(named: "slider_green_track")
        customSlider.setMaximumTrackImage(rightTrackImage, for: .normal)

        // Set the sliding thumb image (normal and highlighted).
        let thumbImageConfig = UIImage.SymbolConfiguration(scale: .large)
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: thumbImageConfig)
        customSlider.setThumbImage(thumbImage, for: .normal)
        let thumbImageHighlighted = UIImage(systemName: "circle", withConfiguration: thumbImageConfig)
        customSlider.setThumbImage(thumbImageHighlighted, for: .highlighted)

        customSlider.minimumValue = 0
        customSlider.maximumValue = 100
        customSlider.isContinuous = false
        customSlider.value = 84

        customSlider.addTarget(self, action: #selector(SliderViewController.sliderValueDidChange(_:)), for: .valueChanged)
    }
    
    func configureMinMaxImageSlider() {
        minMaxImageSlider.minimumValueImage = UIImage(systemName: "tortoise")
        minMaxImageSlider.maximumValueImage = UIImage(systemName: "hare")
        
        minMaxImageSlider.addTarget(self, action: #selector(SliderViewController.sliderValueDidChange(_:)), for: .valueChanged)
    }
    
    // MARK: - Actions

    @objc
    func sliderValueDidChange(_ slider: UISlider) {
        print("A slider changed its value: \(slider).")
    }
}
