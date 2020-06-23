/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UIView subclass containing the quilt user interface, grid, and area for stitching.
*/

import UIKit

class QuiltView: UIView, UIPointerInteractionDelegate {

    private static let straightLineStitchUserDefaultsKey = "useStrightLineStitch"
    private static let colorUserDefaultsKey = "threadColor"

    var useStraightLineStitch: Bool {
        get {
            return UserDefaults.standard.bool(forKey: QuiltView.straightLineStitchUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: QuiltView.straightLineStitchUserDefaultsKey)
            UserDefaults.standard.synchronize()
        }
    }
    var stitchColor: UIColor = {
        var result = UIColor(named: "GreyThread")!
        do {
            if let data = UserDefaults.standard.object(forKey: QuiltView.colorUserDefaultsKey) as? Data {
                if let color = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: data) as? UIColor {
                    result = color
                }
            }
        } catch {
        }
        return result
      }() {
        didSet {
            self.setNeedsLayout()
            do {
                let colorData = try NSKeyedArchiver.archivedData(withRootObject: stitchColor, requiringSecureCoding: true)
                UserDefaults.standard.set(colorData, forKey: QuiltView.colorUserDefaultsKey)
                UserDefaults.standard.synchronize()
            } catch {
            }
        }
    }

    let gridHeight = CGFloat(20.0)
    var stitchLocations = [CGPoint]()
    var lineDashPattern = [NSNumber]()
    let stitchLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedInit()
    }

    func sharedInit() {
        let patchworkView = PatchworkView()
        patchworkView.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(patchworkView, at: 0)
        patchworkView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor).isActive = true
        patchworkView.centerYAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerYAnchor).isActive = true

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
        stitchLayer.lineWidth = 2
        stitchLayer.fillColor = UIColor.clear.cgColor
        stitchLayer.lineCap = .round
        self.layer.addSublayer(stitchLayer)

        // Add a pointer interaction for the "editor" area Quilt view.
        self.addInteraction(UIPointerInteraction(delegate: self))
    }

    // Supply custom regions that correspond to grid lines when "useStraightLineStitch" is enabled.
    func pointerInteraction(_ interaction: UIPointerInteraction,
                            regionFor request: UIPointerRegionRequest,
                            defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        if useStraightLineStitch {
            let regionNumber = floor(request.location.y / gridHeight)
            return UIPointerRegion(rect: CGRect(x: 0, y: regionNumber * gridHeight, width: self.bounds.size.width, height: gridHeight))
        } else {
            return defaultRegion
        }
    }

    // Supply pointer style with custom crosshair shape.
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        let crosshair = UIPointerShape.path(crosshairBezierPath())

        if useStraightLineStitch {
            return UIPointerStyle(shape: crosshair, constrainedAxes: [.vertical])
        } else {
            return UIPointerStyle(shape: crosshair)
        }
    }

    func crosshairBezierPath() -> UIBezierPath {
        let crosshairPath = UIBezierPath()
        crosshairPath.move(to: CGPoint(x: -1.5, y: 1.5))
        crosshairPath.addLine(to: CGPoint(x: -1.5, y: 10))
        crosshairPath.addArc(withCenter: CGPoint(x: 0, y: 10),
                             radius: 1.5,
                             startAngle: CGFloat.pi,
                             endAngle: 0,
                             clockwise: false)
        crosshairPath.addLine(to: CGPoint(x: 1.5, y: 1.5))
        crosshairPath.addLine(to: CGPoint(x: 10, y: 1.5))
        crosshairPath.addArc(withCenter: CGPoint(x: 10, y: 0),
                             radius: 1.5,
                             startAngle: CGFloat.pi / 2.0,
                             endAngle: CGFloat.pi * 1.5,
                             clockwise: false)
        crosshairPath.addLine(to: CGPoint(x: 1.5, y: -1.5))
        crosshairPath.addLine(to: CGPoint(x: 1.5, y: -10))
        crosshairPath.addArc(withCenter: CGPoint(x: 0, y: -10),
                             radius: 1.5,
                             startAngle: 0,
                             endAngle: CGFloat.pi,
                             clockwise: false)
        crosshairPath.addLine(to: CGPoint(x: -1.5, y: -1.5))
        crosshairPath.addLine(to: CGPoint(x: -10, y: -1.5))
        crosshairPath.addArc(withCenter: CGPoint(x: -10, y: 0),
                             radius: 1.5,
                             startAngle: CGFloat.pi * 1.5,
                             endAngle: CGFloat.pi / 2.0,
                             clockwise: false)
        crosshairPath.close()
        return crosshairPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateDashedLinePattern()
    }

    func updateDashedLinePattern() {
        let path = CGMutablePath()
        stitchLayer.strokeColor = self.stitchColor.cgColor
        if stitchLocations.count >= 2 {
            path.addLines(between: stitchLocations)
            lineDashPattern.removeAll()
            
            for (index, _) in stitchLocations.enumerated() {
                if index < stitchLocations.count - 1 {
                    let adjustment = CGFloat((index % 2 == 0) ? -0.5 : 0.5)
                    lineDashPattern.append(self.distanceBetweenPoints(from: stitchLocations[index],
                                                                      toPoint: stitchLocations[index + 1]) + adjustment as NSNumber)
                }
            }
            stitchLayer.lineDashPattern = lineDashPattern
        }
        stitchLayer.path = path
    }

    func distanceBetweenPoints(from: CGPoint, toPoint: CGPoint) -> CGFloat {
        return sqrt(pow((from.x - toPoint.x), 2) + pow((from.y - toPoint.y), 2))
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            var location = sender.location(in: self)
            if useStraightLineStitch {
                location.y = round(((location.y + (gridHeight / 2.0)) / gridHeight)) * gridHeight - gridHeight / 2.0
            }
            stitchLocations.append(location)
            self.setNeedsLayout()
        }
    }

    func ripLastStitch() {
        if !stitchLocations.isEmpty {
            stitchLocations.removeLast()
        }
        self.setNeedsLayout()
    }

    func ripAllStitches() {
        stitchLocations.removeAll()
        self.setNeedsLayout()
    }
    
}
