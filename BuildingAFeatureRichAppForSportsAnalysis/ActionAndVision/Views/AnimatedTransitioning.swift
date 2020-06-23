/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Various animated view transitions.
*/

import UIKit

enum AnimatedTransitionType {
    case fadeIn
    case fadeOut
    case popUp
    case popOut
}

protocol AnimatedTransitioning {
    func perform(transition: AnimatedTransitionType, duration: TimeInterval)
    func perform(transition: AnimatedTransitionType, duration: TimeInterval, completion: (() -> Void)?)
    func perform(transitions: [AnimatedTransitionType], durations: [TimeInterval], delayBetween: TimeInterval, completion: (() -> Void)?)
}

extension AnimatedTransitioning where Self: UIView {
    func perform(transition: AnimatedTransitionType, duration: TimeInterval) {
        perform(transition: transition, duration: duration, completion: nil)
    }
    
    func perform(transition: AnimatedTransitionType, duration: TimeInterval, completion: (() -> Void)?) {
        switch transition {
        case .fadeIn:
            UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve) {
                self.isHidden = false
            } completion: { _ in
                completion?()
            }
        case .fadeOut:
            UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve) {
                self.isHidden = true
            } completion: { _ in
                completion?()
            }
        case .popUp:
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 5,
                           options: [.curveEaseIn], animations: {
                self.transform = CGAffineTransform.identity
                self.alpha = 1
            }) { _ in
                completion?()
            }
        case .popOut:
            alpha = 1
            transform = CGAffineTransform.identity
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.alpha = 0
            }) { _ in
                completion?()
            }
        }
    }
    
    func perform(transitions: [AnimatedTransitionType], durations: [TimeInterval],
                 delayBetween: TimeInterval, completion: (() -> Void)?) {

        guard let transition = transitions.first else {
            completion?()
            return
        }
        
        let duration = durations.first ?? 0.25
        let view = self
        view.perform(transition: transition, duration: duration) {
            let remainingTransitions = Array(transitions.dropFirst())
            let remainingDurations = Array(durations.dropFirst())
            if !remainingTransitions.isEmpty {
                Timer.scheduledTimer(withTimeInterval: delayBetween, repeats: false) { _ in
                    view.perform(transitions: remainingTransitions, durations: remainingDurations, delayBetween: delayBetween, completion: completion)
                }
            } else {
                completion?()
            }
        }
    }
}
