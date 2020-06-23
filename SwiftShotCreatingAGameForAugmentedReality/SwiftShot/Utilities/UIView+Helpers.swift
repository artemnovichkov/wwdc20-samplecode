/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for animation on UIView.
*/

import UIKit

extension UIView {
    
    func fadeInFadeOut(duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            self.alpha = 1.0
        }, completion: { finished in
            if finished {
                self.isHidden = false
                UIView.animate(withDuration: duration, delay: 1.0, options: .curveEaseOut, animations: {
                    self.alpha = 0.0
                }, completion: { _ in
                    self.isHidden = true
                })
            } else {
                self.isHidden = true
            }
        })
    }
    
}
