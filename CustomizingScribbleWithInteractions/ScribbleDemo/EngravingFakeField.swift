/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays a field where the user can enter engraving text.
*/

import UIKit

/*
 EngravingFakeField demonstrates the use of UIIndirectScribbleInteraction to
 allow writing directly into a view that looks like a text field but would
 normally require a tap to gain focus.
 */
class EngravingFakeField: UIView, UITextFieldDelegate, UIIndirectScribbleInteractionDelegate {
    
    // This class uses Strings as Scribble element identifiers, but it could
    // also use any other type that conforms to Hashable.
    typealias EngravingElementIdentifier = String

    var placeholderLabel = UILabel()
    
    var engravingLabel = UILabel()

    var editingTextField: UITextField?
    
    var indirectScribbleInteraction: UIIndirectScribbleInteraction<EngravingFakeField>!
        
    var engravingText = ""
    
    var isEditingEngraving = false {
        didSet {
            if oldValue != isEditingEngraving {
                // Update everything that depends on this value.
                updateEngravingLabel()
                updatePlaceholder()
                updateEditingField()
                updateOutline()
            }
        }
    }
    
    struct Constants {
        static let viewSize = CGSize(width: 350, height: 90)
        static let visibleBoundsInset = CGSize(width: 50, height: 20)
        static let fieldInset = CGSize(width: 8, height: 2)
        static let fontSize: CGFloat = 16.0
    }
    
    // MARK: - UIView Overrides
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)

        // By installing a UIIndirectScribbleInteraction on this view and
        // responding to the required delegate methods, we allow Scribble to
        // find this view and consider it as a writing area.
        indirectScribbleInteraction = UIIndirectScribbleInteraction(delegate: self)
        addInteraction(indirectScribbleInteraction)
        
        updateEngravingLabel()
        updatePlaceholder()
        updateEditingField()
        updateOutline()

        // Recognizer for tap gesture to trigger installing and focusing the
        // text field.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)
        
        // Make the main view transparent.
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return Constants.viewSize
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        // Only show the outline when there's no engraving text yet.
        let wantsOutline = isEditingEngraving || engravingText.isEmpty
        
        if wantsOutline {
            let dashedBorderWidth: CGFloat = 4.0

            // Draw the dashed outline.
            let outlinePath = UIBezierPath(roundedRect: fieldVisibleFrame, cornerRadius: 8)
            context.setStrokeColor(UIColor.gray.cgColor)
            context.setLineWidth(dashedBorderWidth)
            context.setLineDash(phase: 0, lengths: [5, 5])
            outlinePath.stroke()
        }
        
    }
    
    // MARK: - External Actions

    func finishEditing() {
        isEditingEngraving = false
    }
    
    // MARK: - UIIndirectScribbleInteractionDelegate
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, requestElementsIn rect: CGRect,
                                     completion: @escaping ([ElementIdentifier]) -> Void) {
        // Since we only have one element, we won't need to identify it later,
        // so we can simply use a constant identifier.
        completion(["EngravingIdentifier"])
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, frameForElement elementIdentifier: EngravingElementIdentifier) -> CGRect {
        // We want to make the whole view writable, so include the entire bounds.
        return bounds
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, isElementFocused elementIdentifier: EngravingElementIdentifier) -> Bool {
        // Indicate if our only element is currently installed and focused.
        return editingTextField?.isFirstResponder ?? false
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, focusElementIfNeeded elementIdentifier: EngravingElementIdentifier,
                                     referencePoint focusReferencePoint: CGPoint, completion: @escaping ((UIResponder & UITextInput)?) -> Void) {
        // Make sure the text field is installed.
        isEditingEngraving = true

        // If the field is already focused, you can ignore this call, but you
        // still need to call the completion handler.
        if !(editingTextField!.isFirstResponder) {

            // Text fields tend to scroll to the end when focused, if the text
            // overflows the field.
            // To avoid this and keep the layout stable, set the initial
            // selection using the reference point before making it first
            // responder.
            let pointInInputView = editingTextField!.textInputView.convert(focusReferencePoint, from: interaction.view)
            if let selectionPosition = editingTextField!.closestPosition(to: pointInInputView) {
                editingTextField!.selectedTextRange = editingTextField?.textRange(from: selectionPosition, to: selectionPosition)
            }
            
            editingTextField!.becomeFirstResponder()
        }
        
        completion(editingTextField)
    }

    func indirectScribbleInteraction(_ interaction: UIInteraction, willBeginWritingInElement elementIdentifier: EngravingElementIdentifier) {
        // Hide the placeholder while writing, so it doesn't overlap the strokes.
        updateEngravingLabel()
        updatePlaceholder()
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, didFinishWritingInElement elementIdentifier: EngravingElementIdentifier) {
        // We can re-show the placeholder when writing finishes, if appropriate.
        updateEngravingLabel()
        updatePlaceholder()
    }
    
    // MARK: - UI Elements Updating
    
    func updateEditingField() {
        // Install or uninstall the field as needed.
        if isEditingEngraving && editingTextField == nil {
            let newTextField = UITextField(frame: fieldVisibleFrame.insetBy(dx: Constants.fieldInset.width, dy: Constants.fieldInset.height))
            newTextField.delegate = self
            newTextField.addTarget(self, action: #selector(handleTextFieldDidChange(_:)), for: .editingChanged)

            newTextField.text = engravingText
            newTextField.textAlignment = .center
            newTextField.font = engravingFont

            addSubview(newTextField)
            editingTextField = newTextField
            
        } else if !isEditingEngraving, let textFieldToRemove = editingTextField {
            textFieldToRemove.resignFirstResponder()
            textFieldToRemove.removeFromSuperview()
            editingTextField = nil
        }
    }
        
    func updateEngravingLabel() {

        // Initial setup of the engraving label.
        if engravingLabel.superview == nil {
            addSubview(engravingLabel)
            
            engravingLabel.font = engravingFont
            engravingLabel.textColor = .darkGray
            engravingLabel.shadowColor = UIColor.white.withAlphaComponent(0.5)
            engravingLabel.shadowOffset = CGSize(width: 0, height: 1)
            engravingLabel.translatesAutoresizingMaskIntoConstraints = false
            engravingLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            engravingLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            let engravingLabelWidth = fieldVisibleFrame.width - (Constants.fieldInset.width * 2)
            engravingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: engravingLabelWidth).isActive = true
        }
        
        engravingLabel.text = engravingText

        // Hide while writing with Scribble, or while the text field is visible.
        let shouldBeHidden = indirectScribbleInteraction.isHandlingWriting || isEditingEngraving || engravingText.isEmpty
        engravingLabel.isHidden = shouldBeHidden
    }
    
    func updatePlaceholder() {

        // Initial setup of the placeholder label.
        if placeholderLabel.superview == nil {
            addSubview(placeholderLabel)
            
            placeholderLabel.text = NSLocalizedString("Add engraving here", comment: "Placeholder for the engraving area")
            placeholderLabel.font = engravingFont
            placeholderLabel.textColor = .gray
            placeholderLabel.shadowColor = UIColor.white.withAlphaComponent(0.5)
            placeholderLabel.shadowOffset = CGSize(width: 0, height: 1)
            placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
            placeholderLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            placeholderLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        }
        
        // Hide the placeholder when:
        // - Actively writing with Scribble, or
        // - Editing with the real text field, or
        // - The engraving text is not empty anymore.
        let shouldBeHidden = indirectScribbleInteraction.isHandlingWriting || isEditingEngraving || !engravingText.isEmpty
        placeholderLabel.isHidden = shouldBeHidden
    }
    
    func updateOutline() {
        setNeedsDisplay()
    }
    
    var engravingFont: UIFont {
        UIFont.systemFont(ofSize: Constants.fontSize)
    }

    var fieldVisibleFrame: CGRect {
        // Return the rect where the dotted outline will be drawn, which is
        // smaller than the view itself.
        let normalFrame = CGRect(origin: .zero, size: intrinsicContentSize)
        return normalFrame.insetBy(dx: Constants.visibleBoundsInset.width, dy: Constants.visibleBoundsInset.height)
    }
    
    // MARK: - Event Handling

    @objc
    func handleTextFieldDidChange(_ textField: UITextField) {
        // Keep track of the current engraving string.
        engravingText = textField.text ?? ""
    }
    
    @objc
    func handleTapGesture() {
        // On tap, install the text field and focus it.
        isEditingEngraving = true
        editingTextField!.becomeFirstResponder()
    }

    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // When the text field loses first responder, reflect that in our
        // internal state and adjust the visibility of the labels.
        isEditingEngraving = false
    }
}
