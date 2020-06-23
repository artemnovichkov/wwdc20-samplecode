/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Illustrates the new per-segment handling available with UISegmentedControl
 when you create segments with UIActions.
*/

import UIKit

class SegmentedControlDemoViewController: UIViewController {
    
    enum Colors: Int, CaseIterable, CustomStringConvertible {
        case red = 0, green, blue
        
        var description: String {
            return ["Red", "Green", "Blue"][self.rawValue]
        }
        
        func color() -> UIColor {
            return [.red, .green, .blue][self.rawValue]
        }
    }
    
    enum Shapes: Int, CaseIterable, CustomStringConvertible {
        case seal = 0, shield, capsule
        
        var description: String {
            return ["Seal", "Shield", "Capsule"][self.rawValue]
        }
        
        func image() -> UIImage {
            let symbolName = ["seal.fill", "shield.fill", "capsule.fill"][self.rawValue]
            return UIImage(systemName: symbolName)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .large)

        let colorSelector = UISegmentedControl(frame: .zero, actions: Colors.allCases.map { color in
            UIAction(title: color.description) { [unowned imageView] _ in
                imageView.tintColor = color.color()
            }
        })
        colorSelector.selectedSegmentIndex = 0
        let shapeSelector = UISegmentedControl(frame: .zero, actions: Shapes.allCases.map { shape in
            UIAction(title: shape.description) { [unowned imageView] _ in
                imageView.image = shape.image()
            }
        })
        shapeSelector.selectedSegmentIndex = 0
        imageView.tintColor = Colors(rawValue: colorSelector.selectedSegmentIndex)!.color()
        imageView.image = Shapes(rawValue: shapeSelector.selectedSegmentIndex)!.image()

        let stackView = UIStackView(arrangedSubviews: [imageView, colorSelector, shapeSelector])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0)
        ])
    }

}
