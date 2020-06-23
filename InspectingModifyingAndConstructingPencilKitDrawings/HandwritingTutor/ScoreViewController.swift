/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for showing the final score.
*/

import UIKit

let emojiScore = ["😩", "😟", "😐", "😊", "😄", "🤩"]

class ScoreViewController: UIViewController {
    @IBOutlet weak var scoreEmojiView: UILabel!
    @IBOutlet weak var scoreTextField: UILabel!
    
    var score = 1.0
    let fireworksThresholdScore = 0.8

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the score and emoji result.
        let emoji = emojiScore[min(Int(Double(emojiScore.count) * score), emojiScore.count - 1)]
        scoreEmojiView.text = emoji
        scoreTextField.text = "\(Int(score * 100))%"
        
        if score > fireworksThresholdScore {
            addFireworks()
        }
    }
    
    // MARK: - Fireworks
    
    func addFireworks() {
        // Adjust the colors to always work for fireworks, regardless of UI style.
        // Always use dark black background, and white text.
        view.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        scoreTextField.textColor = .white
        
        // Setup an emitter layer.
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterSize = view.bounds.size
        emitterLayer.emitterShape = .rectangle
        emitterLayer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        emitterLayer.renderMode = .additive
        
        // Setup the seed for the firework.
        let seedCell = CAEmitterCell()
        seedCell.color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.2).cgColor
        seedCell.redRange = 0.8
        seedCell.greenRange = 0.8
        seedCell.blueRange = 0.8
        seedCell.lifetime = 1
        seedCell.birthRate = 4
        
        // Setup the firework.
        let fireworkCell = CAEmitterCell()
        fireworkCell.contents = UIImage(named: "star")?.cgImage
        fireworkCell.alphaRange = 0.1
        fireworkCell.lifetime = 100
        fireworkCell.lifetimeRange = 10
        fireworkCell.birthRate = 10_000
        fireworkCell.velocity = 200
        fireworkCell.scale = 0.2
        fireworkCell.spin = 3
        fireworkCell.alphaSpeed = -0.2
        fireworkCell.scaleSpeed = -0.1
        fireworkCell.duration = 0.1
        fireworkCell.emissionRange = CGFloat.pi * 2
        fireworkCell.yAcceleration = 80
        
        seedCell.emitterCells = [fireworkCell]
        emitterLayer.emitterCells = [seedCell]
        view.layer.insertSublayer(emitterLayer, at: 0)
    }
}
