/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the slide-to-slide zoom animation for the Photos project slideshow extension.
*/

import Cocoa
import PhotosUI

protocol AnimatableSlide {
    var contentAspectRatio: CGFloat? { get }
    var preferredZoomRect: CGRect? { get }
}
protocol Animator {

    var transitionDuration: TimeInterval { get set }

    // It is expected that both the from and to view controller have the same parent view controller.
    func transition(from fromViewController: NSViewController & AnimatableSlide,
                    to toViewController: NSViewController & AnimatableSlide,
                    completionHandler: @escaping () -> Void)
    func animate(slide viewController: NSViewController & AnimatableSlide) -> TimeInterval
}

struct RoiZoomAnimator: Animator {
    var transitionDuration: TimeInterval = 2
    var minAnimationDuration: TimeInterval = 3
    var animationVelocity: Double = 1.5

    func transition(from fromViewController: NSViewController & AnimatableSlide,
                    to toViewController: NSViewController & AnimatableSlide,
                    completionHandler: @escaping () -> Void) {
        guard let containerView = fromViewController.parent?.view else {
            preconditionFailure("From view controller must have a parent.")
        }
        precondition(fromViewController.parent == toViewController.parent, "Expected that both view controllers have the same parent.")

        let targetView = toViewController.view
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.0
            context.allowsImplicitAnimation = true

            targetView.frame = containerView.bounds
            targetView.alphaValue = 0.0
            containerView.addSubview(targetView)

        }) {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = self.transitionDuration
                context.allowsImplicitAnimation = true
                targetView.alphaValue = 1.0
                fromViewController.view.alphaValue = 0.0
            }) {
                let fromView = fromViewController.view
                fromView.removeFromSuperview()
                completionHandler()
            }
        }
    }

    func animate(slide viewController: NSViewController & AnimatableSlide) -> TimeInterval {
        guard let containerView = viewController.view.superview else {
            preconditionFailure("View controller view must have a superview.")
        }

        let containerBounds = containerView.bounds
        let sourceFrame = viewController.view.frame
        let targetFrame = self.targetFrame(for: viewController, in: containerBounds)
        let distance = sourceFrame.distance(to: targetFrame, in: containerBounds.size)
        let calculatedDuration: TimeInterval = Double(distance) / animationVelocity
        let duration: TimeInterval = max(calculatedDuration, minAnimationDuration)

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = duration
            context.allowsImplicitAnimation = true
            viewController.view.frame = targetFrame
        })

        return duration
    }

    func targetFrame(for viewController: NSViewController & AnimatableSlide, in rect: CGRect) -> CGRect {
        let normalizedZoomRect = self.zoomRect(for: viewController)

        let aspectRatio = viewController.contentAspectRatio ?? rect.size.aspectRatio
        let imageRect = CGRect(aspectRatio: aspectRatio, fitting: rect)
        let denormalizedFrame = normalizedZoomRect.denormalized(in: imageRect)
        let fillingFrame = CGRect(aspectRatio: rect.size.aspectRatio, fitting: denormalizedFrame)
        let targetFrame = fillingFrame.zoomRect(in: rect.size)
        return targetFrame
    }

    func zoomRect(for slide: AnimatableSlide) -> CGRect {
        var targetRect = CGRect(x: 0.25, y: 0.3, width: 0.5, height: 0.5)

        if let modelZoomRect = slide.preferredZoomRect {
            targetRect = modelZoomRect.insetBy(dx: -0.2, dy: -0.2)
            targetRect.constrainToNormRect()
        }

        return targetRect
    }
}
