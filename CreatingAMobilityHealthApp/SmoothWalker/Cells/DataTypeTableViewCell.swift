/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A table view cell with a left-aligned primary value and a right-aligned secondary value.
*/

import UIKit

/// A table view cell with a title and detail value label.
class DataTypeTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
