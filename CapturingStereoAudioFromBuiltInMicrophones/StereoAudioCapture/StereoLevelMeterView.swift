/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple Quartz-based audio level meter class.
*/

import UIKit

struct ChannelLevels {
    let level: Float
    let peakLevel: Float
}

struct StereoChannelLevels {
    let left: ChannelLevels
    let right: ChannelLevels
    static let zero = StereoChannelLevels(left: ChannelLevels(level: 0, peakLevel: 0),
                                          right: ChannelLevels(level: 0, peakLevel: 0))
}

/// Protocol to be adopted by object providing peak and average power levels.
protocol StereoLevelsProvider {
    var levels: StereoChannelLevels { get }
}

class StereoLevelMeterView: UIView {
    
    private let leftChannelMeter = LevelMeterView(frame: .zero)
    private let rightChannelMeter = LevelMeterView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [leftChannelMeter, rightChannelMeter])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 1.0
        
        addSubview(stackView)
        stackView.pinToSuperviewEdges()
    }
    
    // Class providing audio meter data needs to adopt StereoLevelsProvider.
    var levelProvider: StereoLevelsProvider? {
        didSet {
            leftChannelMeter.levelProvider = levelProvider
            rightChannelMeter.levelProvider = levelProvider
        }
    }
    
    func start() {
        leftChannelMeter.installDisplayLink()
        rightChannelMeter.installDisplayLink()
    }
    
    func stop() {
        leftChannelMeter.uninstallDisplayLink()
        rightChannelMeter.uninstallDisplayLink()
    }
}

private class LevelMeterView: UIView {
    
    private struct ColorThreshold {
        let color: UIColor
        let maxValue: CGFloat
    }
    
    private var meterDisplayLink: CADisplayLink?
    
    private var level: CGFloat = 0
    private var peakLevel: CGFloat = 0
    
    private var isActive = false
    
    private let ledBorderColor     = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
    private let ledBackgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
    private let bezelColor         = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
    private let borderWidth: CGFloat = 0.5
    
    private var ledCount = 24
    private lazy var leds: [CALayer] = []
    
    private func rebuildLEDs() {
        layer.sublayers?.removeAll()
        
        var layers = [CALayer]()
        
        for ledIndex in 0..<ledCount {
            
            // Calculate current LED rect
            let rectX = bounds.width * (CGFloat(ledIndex) / CGFloat(ledCount))
            let rectY = CGFloat(0)
            let width = bounds.width * (1.0 / CGFloat(ledCount))
            let height = bounds.height
            
            let ledRect = CGRect(x: rectX, y: rectY, width: width, height: height)
            
            // Create and configure LED layer.
            let ledLayer = CALayer()
            // Inset slightly so there is some slight space between LEDs
            ledLayer.frame = ledRect.insetBy(dx: 0.0, dy: 0.0)
            ledLayer.borderWidth = borderWidth
            ledLayer.borderColor = ledBorderColor.cgColor
            ledLayer.backgroundColor = ledBackgroundColor.cgColor
            
            // Add layer to layer hierachy/
            layer.addSublayer(ledLayer)
            
            layers.append(ledLayer)
        }
        
        leds = layers
    }
    
    private let thresholds = [
        // LED color threshold values
        ColorThreshold(color: #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1), maxValue: 0.5),
        ColorThreshold(color: #colorLiteral(red: 1, green: 1, blue: 0, alpha: 1), maxValue: 0.8),
        ColorThreshold(color: #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1), maxValue: 1.0)
    ]
    
    // Class providing audio meter data needs to adopt AudioLevelProvider.
    var levelProvider: StereoLevelsProvider?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        rebuildLEDs()
        layer.borderWidth = borderWidth
        layer.borderColor = bezelColor.cgColor
    }
    
    // Updates the LED colors based on the current peak and avg power levels.
    private func updateLEDs() {
        
        var lightMinValue = CGFloat(0)
        
        var peakLED = -1
        
        if peakLevel > 0 {
            peakLED = min(Int(peakLevel * CGFloat(ledCount)), ledCount)
        }
        
        for ledIndex in 0..<ledCount {
            
            guard var ledColor = thresholds.first?.color else { continue }
            let ledMaxValue = CGFloat(ledIndex + 1) / CGFloat(ledCount)
            
            // Calculate the LED's color.
            for colorIndex in 0..<thresholds.count - 1 {
                let curr = thresholds[colorIndex]
                let next = thresholds[colorIndex + 1]
                if curr.maxValue <= ledMaxValue {
                    ledColor = next.color
                }
            }
            
            // Calculate the LED light intensity.
            let lightIntensity: CGFloat
            if ledIndex == Int(peakLED) {
                lightIntensity = 1.0
            } else {
                lightIntensity = clamp(intensity: (level - lightMinValue) / (ledMaxValue - lightMinValue))
            }
            
            let fillColor: UIColor
            
            // Calculate the LED color for the current light intensity.
            switch lightIntensity {
                case 0:
                    fillColor = ledBackgroundColor
                case 1:
                    fillColor = ledColor
                default:
                    guard let color = ledColor.cgColor.copy(alpha: lightIntensity) else { return }
                    fillColor = UIColor(cgColor: color)
            }
            
            let ledLayer = leds[ledIndex]
            ledLayer.backgroundColor = fillColor.cgColor
            
            lightMinValue = ledMaxValue
        }
    }
    
    fileprivate func installDisplayLink() {
        meterDisplayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        meterDisplayLink?.preferredFramesPerSecond = 15
        meterDisplayLink?.add(to: .current, forMode: .common)
    }
    
    fileprivate func uninstallDisplayLink() {
        if let displayLink = meterDisplayLink {
            displayLink.remove(from: .current, forMode: .common)
            displayLink.invalidate()
            meterDisplayLink = nil
            reset()
        }
    }
    
    @objc
    private func updateMeter() {
        guard let levels = levelProvider?.levels else { return }
        level = CGFloat(levels.left.level)
        peakLevel = CGFloat(levels.left.peakLevel)
        updateLEDs()
    }
    
    private func clamp(intensity: CGFloat) -> CGFloat {
        if intensity < 0.0 {
            return 0.0
        } else if intensity >= 1.0 {
            return 1.0
        } else {
            return intensity
        }
    }
    
    func reset() {
        level = 0
        peakLevel = 0
        updateLEDs()
    }
    
    override func layoutSubviews() {
        rebuildLEDs()
        super.layoutSubviews()
    }
}
