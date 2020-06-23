/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UITableViewCell subclass to display information about a quake.
*/

import UIKit

class QuakeCell: UITableViewCell {
    
    @IBOutlet weak private var locationLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var magnitudeLabel: UILabel!

    /**
     Configures the cell with a quake instance.
    */
    func configure(with quake: Quake) {
        locationLabel.text = quake.place
        if let quakeTime = quake.time {
            dateLabel.text = QuakeCell.dateFormatter.string(from: quakeTime)
        }
        if let magnitude = quake.magnitude?.floatValue {
            magnitudeLabel.text = String(format: "%.1f", magnitude)
        }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
