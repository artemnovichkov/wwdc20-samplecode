/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A label to present the user with feedback.
*/

import UIKit

@IBDesignable
class MessageLabel: UILabel {
    
    var ignoreMessages = false
		
	override func drawText(in rect: CGRect) {
		let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
		super.drawText(in: rect.inset(by: insets))
	}
    
    func displayMessage(_ text: String, duration: TimeInterval = 3.0) {
        guard !ignoreMessages else { return }
        guard !text.isEmpty else {
            DispatchQueue.main.async {
                self.isHidden = true
                self.text = ""
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isHidden = false
            self.text = text
            
            // Use a tag to tell if the label has been updated.
            let tag = self.tag + 1
            self.tag = tag
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                // Do not hide if this method is called again before this block kicks in.
                if self.tag == tag {
                    self.isHidden = true
                }
            }
        }
    }
}
