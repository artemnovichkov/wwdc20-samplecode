/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View that displays the throw count as a progress.
*/

import UIKit

class ProgressView: UIView, AnimatedTransitioning {
    
    var throwCount: Int = 0 {
        didSet {
            updatePathLayer()
        }
    }
    var throwType: ThrowType = .none {
        didSet {
            updateThrowTypeIcon()
        }
    }
    private var progressBarHeight: CGFloat = 8
    private var throwTypeIconSize: CGFloat = 16
    private var prevPosition: CGFloat = 0
    private var newPosition: CGFloat = 0
    private let throwTypeIcon = UIImageView()
    private var pathLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    func incrementThrowCount() {
        throwCount += 1
    }
    
    private func animateSpeedChart() {
        let xPos = bounds.width * (1 - CGFloat(throwCount) / CGFloat(GameConstants.maxThrows))
        let yPos = bounds.height - progressBarHeight - throwTypeIconSize
        UIView.animate(withDuration: 1, delay: 0.0, options: .curveEaseIn, animations: {
            self.throwTypeIcon.frame = CGRect(x: xPos, y: yPos, width: self.throwTypeIconSize, height: self.throwTypeIconSize)
        }, completion: nil)
        let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        progressAnimation.duration = 1
        progressAnimation.fromValue = prevPosition / bounds.width
        progressAnimation.toValue = 1
        progressAnimation.fillMode = .forwards
        progressAnimation.isRemovedOnCompletion = false
        progressLayer.add(progressAnimation, forKey: "animateSpeedChart")
        prevPosition = newPosition
    }

    private func initialSetup() {
        isOpaque = false
        backgroundColor = .clear
        let xPos = bounds.width - throwTypeIconSize
        let yPos = bounds.height - progressBarHeight - throwTypeIconSize
        throwTypeIcon.frame = CGRect(x: xPos, y: yPos, width: throwTypeIconSize, height: throwTypeIconSize)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: bounds.width, y: (bounds.height - progressBarHeight / 2)))
        linePath.addLine(to: CGPoint(x: newPosition, y: (bounds.height - progressBarHeight / 2)))
        pathLayer.path = linePath.cgPath
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4499411387).cgColor
        pathLayer.lineCap = .round
        pathLayer.lineWidth = progressBarHeight
        layer.addSublayer(pathLayer)
        self.addSubview(throwTypeIcon)
    }
    
    private func updateThrowTypeIcon() {
        throwTypeIcon.alpha = 0.65
        throwTypeIcon.image = UIImage(named: throwType.rawValue)
    }

    private func updatePathLayer() {
        newPosition = bounds.width * (1 - CGFloat(throwCount) / CGFloat(GameConstants.maxThrows))
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: bounds.width, y: (bounds.height - progressBarHeight / 2)))
        linePath.addLine(to: CGPoint(x: newPosition, y: (bounds.height - progressBarHeight / 2)))
        progressLayer.path = linePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = #colorLiteral(red: 0.6078431373, green: 0.9882352941, blue: 0, alpha: 0.7539934132).cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = progressBarHeight
        layer.addSublayer(progressLayer)
        animateSpeedChart()
    }
}
