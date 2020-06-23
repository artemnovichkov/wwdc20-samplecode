/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to use `UITextField`.
*/

import UIKit

class TextFieldViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tintedTextField: UITextField!
    @IBOutlet weak var secureTextField: UITextField!
    @IBOutlet weak var specificKeyboardTextField: UITextField!
    @IBOutlet weak var customTextField: UITextField!
    @IBOutlet weak var searchTextField: CustomTextField!
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextField()
        configureTintedTextField()
        configureSecureTextField()
        configureSpecificKeyboardTextField()
        configureCustomTextField()
        configureSearchTextField()
    }
    
    // MARK: - Configuration

    func configureTextField() {
        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.autocorrectionType = .yes
        textField.returnKeyType = .done
        textField.clearButtonMode = .never
    }

    func configureTintedTextField() {
        tintedTextField.tintColor = UIColor.systemBlue
        tintedTextField.textColor = UIColor.systemGreen

        tintedTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        tintedTextField.returnKeyType = .done
        tintedTextField.clearButtonMode = .never
    }

    func configureSecureTextField() {
        secureTextField.isSecureTextEntry = true

        secureTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        secureTextField.returnKeyType = .done
        secureTextField.clearButtonMode = .always
    }
    
    func configureSearchTextField() {
        searchTextField.placeholder = NSLocalizedString("Enter search text", comment: "")
        searchTextField.returnKeyType = .done
        searchTextField.clearButtonMode = .always
        searchTextField.allowsDeletingTokens = true
        
        // Setup the left view as a symbol image view.
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor.systemGray
        searchTextField.leftView = searchIcon
        searchTextField.leftViewMode = .always
    
        let secondToken = UISearchToken(icon: UIImage(systemName: "staroflife"), text: "Token 2")
        searchTextField.insertToken(secondToken, at: 0)
        
        let firstToken = UISearchToken(icon: UIImage(systemName: "staroflife.fill"), text: "Token 1")
        searchTextField.insertToken(firstToken, at: 0)
    }

    /**	There are many different types of keyboards that you may choose to use.
        The different types of keyboards are defined in the `UITextInputTraits` interface.
        This example shows how to display a keyboard to help enter email addresses.
    */
    func configureSpecificKeyboardTextField() {
        specificKeyboardTextField.keyboardType = .emailAddress

        specificKeyboardTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        specificKeyboardTextField.returnKeyType = .done
    }

    func configureCustomTextField() {
        // Text fields with custom image backgrounds must have no border.
        customTextField.borderStyle = .none

        customTextField.background = UIImage(named: "text_field_background")

        // Create a purple button that, when selected, turns the custom text field's text color to purple.
        let purpleImage = UIImage(named: "text_field_purple_right_view")!
        let purpleImageButton = UIButton(type: .custom)
        purpleImageButton.bounds = CGRect(x: 0, y: 0, width: purpleImage.size.width, height: purpleImage.size.height)
        purpleImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        purpleImageButton.setImage(purpleImage, for: .normal)
        purpleImageButton.addTarget(self, action: #selector(TextFieldViewController.customTextFieldPurpleButtonClicked), for: .touchUpInside)
        customTextField.rightView = purpleImageButton
        customTextField.rightViewMode = .always

        customTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        customTextField.autocorrectionType = .no
        customTextField.returnKeyType = .done
    }
	
    // MARK: - Actions
    
    @objc
    func customTextFieldPurpleButtonClicked() {
        print("The custom text field's purple right view button was clicked.")
    }

}

// MARK: - UITextFieldDelegate

extension TextFieldViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // User changed the text selection.
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Return false to not change text.
        return true
    }
}

// Custom text field for controlling input text placement.
class CustomTextField: UISearchTextField {
    let leftMarginPadding: CGFloat = 12

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.x += leftMarginPadding
        return rect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.x += leftMarginPadding
        return rect
    }
    
}
