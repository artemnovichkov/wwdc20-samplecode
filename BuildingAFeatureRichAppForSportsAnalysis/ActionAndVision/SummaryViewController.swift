/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller to show the game summary.
*/

import UIKit

class SummaryViewController: UIViewController {

    @IBOutlet weak var speedValue: UILabel!
    @IBOutlet weak var angleValue: UILabel!
    @IBOutlet weak var scoreValue: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    private let gameManager = GameManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }

    private func updateUI() {
        let stats = gameManager.playerStats
        backgroundImage.image = gameManager.previewImage
        displayTrajectories()
        // Speed label attributed string
        let speedValueFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28.0, weight: .bold)]
        let speedValueText = NSMutableAttributedString(string: "\(round(stats.avgSpeed * 100) / 100)", attributes: speedValueFont)
        let speedUnitFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22.0, weight: .bold)]
        speedValueText.append(NSAttributedString(string: " MPH", attributes: speedUnitFont))

        // set attributed text on a UILabel
        speedValue.attributedText = speedValueText
        angleValue.text = "\(round(stats.avgReleaseAngle * 100) / 100)°"
        let score = NSMutableAttributedString(string: "\(stats.totalScore)", attributes: [.foregroundColor: UIColor.white])
        score.append(NSAttributedString(string: "/40", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.65)]))
        scoreValue.attributedText = score
    }

    private func displayTrajectories() {
        let stats = gameManager.playerStats
        // Display trajectories
        // Fetch saved throw paths from playerStats and draw each throw on a TrajectoryView.
        let paths = stats.throwPaths
        let frame = view.bounds
        for path in paths {
            let trajectoryView = TrajectoryView(frame: frame)
            trajectoryView.translatesAutoresizingMaskIntoConstraints = false
            // Add each trajectoryView as subview to current view.
            view.addSubview(trajectoryView)
            // Add contraints to make sure trajectoryView is within the safe area.
            NSLayoutConstraint.activate([
                trajectoryView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0),
                trajectoryView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0),
                trajectoryView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
                trajectoryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
            ])
            trajectoryView.addPath(path)
        }
    }
}
