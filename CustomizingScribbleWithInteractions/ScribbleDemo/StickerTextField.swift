/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom text field used to show a sticker added to the background image.
*/

import UIKit

/*
 StickerTextField is a UITextField subclass that can adjust the look and feel
 of the text to look like a sticker over the back of a laptop. It adjusts its
 own frame as the content changes. It also demonstrates adding buttons to the
 shortcuts bar and the Scribble palette through UITextInputAssistantItem.
 */
class StickerTextField: UITextField {
    
    var fontSize: CGFloat = 28.0
    
    let identifier = UUID()
    
    var writableFrame: CGRect {
        frame.inset(by: UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -70))
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        text = ""
        borderStyle = .roundedRect
        backgroundColor = .clear

        updateFont()
        updateSize()
        setupAssistantItemButtons()
    }
    
    convenience init(origin: CGPoint) {
        self.init(frame: CGRect(origin: origin, size: CGSize(width: 12, height: 20)))
    }
    
    func setupAssistantItemButtons() {
        // Buttons to adjust the text color and size.
        let colorImage = UIImage(systemName: "circle.lefthalf.fill")
        let minusImage = UIImage(systemName: "minus.circle")
        let plusImage = UIImage(systemName: "plus.circle")
        
        // Adding the buttons to the inputAssistantItem of this field makes
        // them show up in the shortcuts bar above the keyboard, and in the
        // Scribble floating palette.
        inputAssistantItem.trailingBarButtonGroups = [UIBarButtonItemGroup(barButtonItems: [
            UIBarButtonItem(image: colorImage, style: .done, target: self, action: #selector(toggleColor)),
            UIBarButtonItem(image: minusImage, style: .done, target: self, action: #selector(decreaseFontSize)),
            UIBarButtonItem(image: plusImage, style: .done, target: self, action: #selector(increaseFontSize))],
            representativeItem: nil)
        ]
    }
    
    func updateFont() {
        font = UIFont(name: "Futura-Bold", size: fontSize)
        updateSize(centerResize: true)
    }
    
    func updateSize(centerResize: Bool = false) {
        let oldSize = frame.size
        let size = sizeThatFits(CGSize(width: 1024, height: fontSize))
        let oldOrigin = frame.origin
        
        let deltaX = size.width - oldSize.width
        let deltaY = size.height - oldSize.height
        
        // Adjust the size of the field to fit the current content.
        let origin = centerResize ? CGPoint(x: oldOrigin.x - deltaX / 2, y: oldOrigin.y - deltaY / 2) : oldOrigin
        frame = CGRect(origin: origin, size: size)
    }
    
    @objc
    open func toggleColor() {
        // Toggle color between black and white.
        textColor = (textColor == UIColor.white) ? UIColor.black : UIColor.white
    }

    @objc
    open func increaseFontSize() {
        fontSize = min(fontSize + 2.0, 70)
        updateFont()
    }

    @objc
    open func decreaseFontSize() {
        fontSize = max(fontSize - 2.0, 18)
        updateFont()
    }

}
