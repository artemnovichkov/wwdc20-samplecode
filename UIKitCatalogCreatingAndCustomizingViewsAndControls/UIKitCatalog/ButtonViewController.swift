/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UIButton`.
 The buttons are created using storyboards, but each of the system buttons can be created in code by
 using the UIButton.init(type buttonType: UIButtonType) initializer.
 
 See the UIButton interface for a comprehensive list of the various UIButtonType values.
*/

import UIKit

class ButtonViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var systemTextButton: UIButton!
    @IBOutlet weak var systemContactAddButton: UIButton!
    @IBOutlet weak var systemDetailDisclosureButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var attributedTextButton: UIButton!
    @IBOutlet weak var symbolButton: UIButton!
    @IBOutlet weak var symbolTextButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // All of the buttons are created in the storyboard, but configured below.
        configureSystemTextButton()
        configureSystemContactAddButton()
        configureSystemDetailDisclosureButton()
        configureImageButton()
        configureAttributedTextSystemButton()
        configureSymbolButton()
        configureSymbolTextButton()
        configureMenuButton()
    }

    // MARK: - Configuration

    func configureSystemTextButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")

        systemTextButton.setTitle(buttonTitle, for: .normal)

        systemTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemContactAddButton() {
        systemContactAddButton.backgroundColor = UIColor.clear

        systemContactAddButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemDetailDisclosureButton() {
        systemDetailDisclosureButton.backgroundColor = UIColor.clear

        systemDetailDisclosureButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureImageButton() {
        // To create this button in code you can use `UIButton.init(type: .system)`.

        // Remove the title text.
        imageButton.setTitle("", for: .normal)

        imageButton.tintColor = UIColor.systemPurple

        let imageButtonNormalImage = #imageLiteral(resourceName: "x_icon")
		imageButton.setImage(imageButtonNormalImage, for: .normal)

        // Add an accessibility label to the image.
        imageButton.accessibilityLabel = NSLocalizedString("X", comment: "")

        imageButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureAttributedTextSystemButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")
        
        // Set the button's title for normal state.
		let normalTitleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let normalAttributedTitle = NSAttributedString(string: buttonTitle, attributes: normalTitleAttributes)
        attributedTextButton.setAttributedTitle(normalAttributedTitle, for: .normal)

        // Set the button's title for highlighted state.
        let highlightedTitleAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.systemGreen,
            NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.thick.rawValue
        ]
        let highlightedAttributedTitle = NSAttributedString(string: buttonTitle, attributes: highlightedTitleAttributes)
        attributedTextButton.setAttributedTitle(highlightedAttributedTitle, for: .highlighted)

        attributedTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }
    
    func configureSymbolButton() {
        let buttonImage = UIImage(systemName: "person")
        symbolButton.setImage(buttonImage, for: .normal)
        
        // Add an accessibility label to the image.
        symbolButton.accessibilityLabel = NSLocalizedString("Person", comment: "")
        
        symbolButton.addTarget(self,
                               action: #selector(ButtonViewController.buttonClicked(_:)),
                               for: .touchUpInside)
    }
    
    func configureSymbolTextButton() {
        let buttonImage = UIImage(systemName: "person")
        symbolTextButton.setImage(buttonImage, for: .normal)
        
        symbolTextButton.addTarget(self,
                                   action: #selector(ButtonViewController.buttonClicked(_:)),
                                   for: .touchUpInside)
        
        symbolTextButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        let config = UIImage.SymbolConfiguration(textStyle: .body, scale: .small)
        symbolTextButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
    }
    
    func menuHandler(action: UIAction) {
        Swift.debugPrint("Menu Action '\(action.title)'")
    }
    
    func configureMenuButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")
        menuButton.setTitle(buttonTitle, for: .normal)

        let items = (1...5).map {
            UIAction(title: String(format: NSLocalizedString("ItemTitle", comment: ""), $0.description), handler: menuHandler)
        }
        menuButton.menu = UIMenu(title: NSLocalizedString("ChooseItemTitle", comment: ""), children: items)
        menuButton.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Actions

    @objc
    func buttonClicked(_ sender: UIButton) {
        print("A button was clicked: \(sender).")
    }
}

