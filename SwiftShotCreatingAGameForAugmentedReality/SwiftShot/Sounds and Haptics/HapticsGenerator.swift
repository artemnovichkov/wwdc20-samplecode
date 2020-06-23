/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages haptic effects coordinated with sound and gameplay.
*/

import UIKit

final class HapticsGenerator {
    private let impact = UIImpactFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    func generateImpactFeedback() {
        DispatchQueue.main.async {
            self.impact.impactOccurred()
        }
    }
    
    func generateSelectionFeedback() {
        DispatchQueue.main.async {
            self.selection.selectionChanged()
        }
    }
    
    func generateNotificationFeedback(_ notificationType: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async {
            self.notification.notificationOccurred(notificationType)
        }
    }
}
