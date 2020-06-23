/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom view that lays out selectable buttons in a grid.
*/

import UIKit

protocol ButtonGridViewDelegate: AnyObject {
    func buttonGrid(_ buttonGrid: ButtonGridView, titleForButtonAtIndexPath indexPath: IndexPath) -> String
    func buttonGrid(_ buttonGrid: ButtonGridView, didSelectItemAtIndexPath indexPath: IndexPath)
}

class ButtonGridView: UIView {

    // A UIButton subclass that tracks an index path and dictates its own styling for the grid view.
    class Button: UIButton {
        var indexPath: IndexPath!

        init() {
            super.init(frame: .zero)

            backgroundColor = .darkGray

            setTitleColor(.white, for: .normal)
            layer.cornerRadius = 10.0
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            if context.nextFocusedView == self {
                backgroundColor = .lightGray
            }

            if context.previouslyFocusedView == self {
                backgroundColor = .darkGray
            }
        }
    }

    weak var delegate: ButtonGridViewDelegate?

    // Initialize with the number of columns and rows (not including the header row).
    init(numberOfColumns: Int, numberOfRows: Int, delegate: ButtonGridViewDelegate, titles: [String]) {
        self.delegate = delegate

        super.init(frame: .zero)

        let headerLabels = titles.map { UILabel(text: $0) }
        let headerStackView = UIStackView(arrangedSubviews: headerLabels)
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fillEqually

        var allRows = [headerStackView]

        for row in 0..<numberOfRows {
            var buttons = [Button]()
            for column in 0..<numberOfColumns {
                let indexPath = IndexPath(row: row, section: column)

                let title = delegate.buttonGrid(self, titleForButtonAtIndexPath: indexPath)

                let button = Button()
                button.indexPath = indexPath
                button.setTitle(title, for: .normal)
                button.addTarget(self, action: #selector(didSelectButton(button:)), for: .primaryActionTriggered)

                buttons.append(button)
            }

            let rowStackView = UIStackView(arrangedSubviews: buttons)
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 40.0
            allRows.append(rowStackView)
        }

        let topStackView = UIStackView(arrangedSubviews: allRows)
        topStackView.axis = .vertical
        topStackView.distribution = .fillEqually
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        topStackView.spacing = 40.0
        self.addSubview(topStackView)

        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor),
            topStackView.leftAnchor.constraint(equalTo: leftAnchor),
            topStackView.rightAnchor.constraint(equalTo: rightAnchor),
            topStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectButton(button: Button) {
        delegate?.buttonGrid(self, didSelectItemAtIndexPath: button.indexPath)
    }

}

private extension UILabel {

    /// A convenience initializer that sets up the labels for the styling needed in the grid view.
    convenience init(text: String) {
        self.init()
        self.text = text
        self.textAlignment = .center
    }

}
