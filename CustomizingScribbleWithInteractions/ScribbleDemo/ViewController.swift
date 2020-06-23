/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for the Scribble Demo.
*/

import UIKit

/*
 This view controller demonstrates how to customize the behavior of Scribble
 and how to enable writing in a view that is not normally a text input.
 Specifically, it installs:
 
 * A UIIndirectScribbleInteraction to enable writing with Scribble on the
 background image to create new stickers.
 * A UIScribbleInteraction to disable writing on a specific area on the image
 where the logo is.
 
 It also installs an EngravingFakeField view, which allows adding engraved text
 to the back of the laptop. The class implementing this view contains another
 example of using UIIndirectScribbleInteraction, to enable writing on a
 text-field-lookalike without requiring to tap on it first.
 */
class ViewController: UIViewController, UIIndirectScribbleInteractionDelegate, UIScribbleInteractionDelegate, UITextFieldDelegate {

    var stickerTextFields: [StickerTextField] = []
    
    var stickerContainerView = UIView()
    
    var engravingField = EngravingFakeField()

    // Used to identify the Scribble Element representing the background view.
    let rootViewElementID = UUID()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load background image.
        if let imageView = view as? UIImageView {
            imageView.image = #imageLiteral(resourceName: "wwdc")
        }
    
        // The sticker container view provides the writing area to add new
        // stickers over the background, and has the Scribble interactions.
        stickerContainerView.frame = view.bounds
        stickerContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(stickerContainerView)
        
        // Install a UIScribbleInteraction, which we'll use to disable Scribble
        // when we want to let the Pencil draw instead of write.
        let scribbleInteraction = UIScribbleInteraction(delegate: self)
        stickerContainerView.addInteraction(scribbleInteraction)

        // Install a UIIndirectScribbleInteraction, which will provide the
        // "elements" that represent virtual writing areas.
        let indirectScribbleInteraction = UIIndirectScribbleInteraction(delegate: self)
        stickerContainerView.addInteraction(indirectScribbleInteraction)

        // The Engraving field is a label that looks like a text field that only
        // becomes editable on tap. It is made "writable" with another
        // UIIndirectScribbleInteraction it installs on itself.
        view.addSubview(engravingField)
        engravingField.translatesAutoresizingMaskIntoConstraints = false
        engravingField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        engravingField.centerYAnchor.constraint(equalTo: self.view.topAnchor, constant: 120).isActive = true
        
        // Background tap recognizer.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UIScribbleInteractionDelegate
    
    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        
        // Disable writing over the logo at the center of the image.
        let midX = view.bounds.midX
        let midY = view.bounds.midY
        let nonWritableWidth = view.bounds.height * 0.15
        let nonWritableHeight = view.bounds.height * 0.18
        let centerRect = CGRect(x: midX, y: midY, width: 0.0, height: 0.0).insetBy(dx: -nonWritableWidth, dy: -nonWritableHeight)
        
        return !centerRect.contains(location)
    }
    
    // MARK: - UIIndirectScribbleInteractionDelegate
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, shouldDelayFocusForElement elementIdentifier: UUID) -> Bool {
        // When writing on a blank area, wait until the user stops writing
        // before triggering element focus, to avoid writing distractions.
        return elementIdentifier == rootViewElementID
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, requestElementsIn rect: CGRect,
                                     completion: @escaping ([ElementIdentifier]) -> Void) {

        var availableElementIDs: [UUID] = []

        // Include the identifier of the root view. It must be at the start of
        // the array, so it doesn't cover all the other fields.
        availableElementIDs.append(rootViewElementID)
        
        // Include the text fields that intersect the requested rect.
        // Even though these are real text fields, Scribble can't find them
        // because it doesn't traverse subviews of a view that has a
        // UIIndirectScribbleInteraction.
        for stickerField in stickerTextFields {
            if stickerField.writableFrame.intersects(rect) {
                availableElementIDs.append(stickerField.identifier)
            }
        }

        // Call the completion handler with the array of element identifiers.
        completion(availableElementIDs)
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, isElementFocused elementIdentifier: UUID) -> Bool {
        if elementIdentifier == rootViewElementID {
            // The root element represents the background view, so it never
            // becomes focused itself.
            return false
        } else {
            // For sticker elements, indicate if the corresponding text field
            // is first responder.
            return stickerFieldForIdentifier(elementIdentifier)?.isFirstResponder ?? false
        }
    }
    
    func indirectScribbleInteraction(_ interaction: UIInteraction, frameForElement elementIdentifier: UUID) -> CGRect {
        var elementRect = CGRect.null
        
        if let stickerField = stickerFieldForIdentifier(elementIdentifier) {
            // Scribble is asking about the frame for one of the sticker frames.
            // Return a frame larger than the field itself to make it easier to
            // append text without creating another field.
            elementRect = stickerField.writableFrame
        } else if elementIdentifier == rootViewElementID {
            // Scribble is asking about the background writing area. Return the
            // frame for the whole view.
            elementRect = stickerContainerView.frame
        }
        
        return elementRect
    }
        
    func indirectScribbleInteraction(_ interaction: UIInteraction, focusElementIfNeeded elementIdentifier: UUID,
                                     referencePoint focusReferencePoint: CGPoint, completion: @escaping ((UIResponder & UITextInput)?) -> Void) {

        // Get an existing field at this location, or create a new one if
        // writing in the background.
        let stickerField: StickerTextField?
        if elementIdentifier == rootViewElementID {
            stickerField = addStickerFieldAtLocation(focusReferencePoint)
        } else {
            stickerField = stickerFieldForIdentifier(elementIdentifier)
        }

        // Focus the field. It should have no effect if it was focused already.
        stickerField?.becomeFirstResponder()
        
        // Call the completion handler as expected by the caller.
        // It could be called asynchronously if, for example, there was an
        // animation to insert a new sticker field.
        completion(stickerField)
    }
    
    // MARK: - Text Field Event Handling
            
    @objc
    func handleTextFieldDidChange(_ textField: UITextField) {

        guard let stickerField = textField as? StickerTextField else {
            return
        }
 
        // When erasing the entire text of a sticker, remove the corresponding
        // text field.
        if !removeIfEmpty(stickerField) {
            // The size updates to accommodate the current content.
            stickerField.updateSize()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let stickerField = textField as? StickerTextField else {
            return
        }
        
        removeIfEmpty(stickerField)
    }
    
    // MARK: - Gesture Handling
    
    @objc
    func handleTapGesture() {
        // Unfocus our text fields.
        for stickerField in stickerTextFields where stickerField.isFirstResponder {
            stickerField.resignFirstResponder()
            break
        }

        engravingField.finishEditing()
    }
    
    // MARK: - Sticker Text Field Handling
    
    func stickerFieldForIdentifier(_ identifier: UUID) -> StickerTextField? {
        for stickerField in stickerTextFields where stickerField.identifier == identifier {
            return stickerField
        }
        return nil
    }
    
    func addStickerFieldAtLocation(_ location: CGPoint) -> StickerTextField {

        let stickerField = StickerTextField(origin: location)
        stickerField.delegate = self
        stickerField.addTarget(self, action: #selector(handleTextFieldDidChange(_:)), for: .editingChanged)
        stickerTextFields.append(stickerField)

        stickerContainerView.addSubview(stickerField)

        return stickerField
    }

    func remove(stickerField: StickerTextField) {
        if let index = stickerTextFields.firstIndex(of: stickerField) {
            stickerTextFields.remove(at: index)
        }
        stickerField.resignFirstResponder()
        stickerField.removeFromSuperview()
    }
    
    @discardableResult
    func removeIfEmpty(_ stickerField: StickerTextField) -> Bool {
        let textLength = stickerField.text?.count ?? 0
        if textLength == 0 {
            remove(stickerField: stickerField)
            return true
        }
        return false
    }
    
}

