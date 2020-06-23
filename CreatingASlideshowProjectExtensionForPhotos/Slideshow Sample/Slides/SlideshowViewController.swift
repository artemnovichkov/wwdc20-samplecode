/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the slideshow view controller for the Photos project slideshow extension.
*/

import Cocoa

class SlideshowViewController: NSViewController {

    lazy var animator: Animator = RoiZoomAnimator()

    var models = [AssetModel]() {
        didSet {
            modelIterator = models.makeIterator()
        }
    }

    private var modelIterator: IndexingIterator<[AssetModel]> = [AssetModel]().makeIterator()
    private var nextSlideController: SlideViewController?
    private var currentSlideController: SlideViewController?

    private var timer: Timer?

    private func nextAssetModel() -> AssetModel? {
        var model = modelIterator.next()
        if model == nil {
            modelIterator = models.makeIterator()
            model = modelIterator.next()
        }
        return model
    }

    deinit {
        timer?.invalidate()
    }

    private var itemSizeForPreload: CGSize {
        let backingScaleFactor: CGFloat = view.window?.backingScaleFactor ?? 1.0
        let scaleFactor = backingScaleFactor * 1.5
        let size = view.bounds.size.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        return size
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = NSColor.black.cgColor
    }

    @discardableResult
    private func loadNextSlide() -> SlideViewController? {
        precondition(nextSlideController == nil)
        guard let model = nextAssetModel() else { return nil }

        let slideController = SlideViewController()
        slideController.preload(assetModel: model, targetSize: itemSizeForPreload)
        nextSlideController = slideController
        return slideController
    }

    func startSlideshow(with models: [AssetModel]) {
        self.models = models
        guard let initialSlide = loadNextSlide() else { return }
        currentSlideController = initialSlide
        nextSlideController = nil
        addChild(initialSlide)
        let slideView = initialSlide.view
        view.addSubview(slideView)
        slideView.frame = view.bounds

        // preload next slide
        loadNextSlide()

        let duration = animator.animate(slide: initialSlide)
        timer = Timer.scheduledTimer(withTimeInterval: duration - animator.transitionDuration * 0.5, repeats: false) { [weak self] (_) in
            self?.transitionToNext()
        }
    }

    func transitionToNext() {
        guard let nextSlideController = nextSlideController, let currentSlideController = currentSlideController else { return }
        addChild(nextSlideController)
        animator.transition(from: currentSlideController, to: nextSlideController) {
            currentSlideController.removeFromParent()
        }
        let duration = animator.animate(slide: nextSlideController)
        timer = Timer.scheduledTimer(withTimeInterval: duration - animator.transitionDuration * 0.5, repeats: false) { [weak self] (_) in
            self?.transitionToNext()
        }

        self.currentSlideController = nextSlideController
        self.nextSlideController = nil
        loadNextSlide()
    }
}
