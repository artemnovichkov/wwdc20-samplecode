/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's custom player view controller.
*/

import AVKit
import Combine
import UIKit

protocol CustomPlayerControlsViewDelegate: class {
    func controlsViewDidRequestStartPictureInPicture(_ controlsView: CustomPlayerControlsView)
    func controlsViewDidRequestStopPictureInPicture(_ controlsView: CustomPlayerControlsView)
    func controlsViewDidRequestControlsDismissal(_ controlsView: CustomPlayerControlsView)
    func controlsViewDidRequestPlayerDismissal(_ controlsView: CustomPlayerControlsView)
}

class CustomPlayerControlsView: UIView {

    private class Button: UIButton {

        init(title: String, image: UIImage?) {
            super.init(frame: .zero)
            self.backgroundColor = .darkGray
            self.tintColor = .white
            self.setTitleColor(.white, for: .normal)
            self.setTitleColor(.darkGray, for: .focused)
            self.setTitle(title, for: .normal)
            self.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.imageView?.contentMode = .scaleAspectFit
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.height += 20
            return size
        }
    }

    weak var delegate: CustomPlayerControlsViewDelegate?

    private weak var player: AVPlayer?
    private weak var pipController: AVPictureInPictureController?

    private let buttonStackView = UIStackView()

    private let progressView = UIProgressView()
    private var progressTimer: Timer!

    private var canStopPictureInPictureCancellable: Cancellable?

    init(player: AVPlayer?, pipController: AVPictureInPictureController?) {
        self.player = player
        self.pipController = pipController

        super.init(frame: .zero)

        setUpViewLayout()

        progressTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let player = player, let item = player.currentItem else { return }
            let progress = CMTimeGetSeconds(player.currentTime()) / CMTimeGetSeconds(item.duration)
            self?.progressView.progress = Float(progress)
        }
        RunLoop.main.add(self.progressTimer, forMode: .default)

        let menuGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuGestureHandler(recognizer:)))
        menuGestureRecognizer.allowedPressTypes = [UIPress.PressType.menu].map { $0.rawValue as NSNumber }
        addGestureRecognizer(menuGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.progressTimer?.invalidate()
        self.progressTimer = nil
        self.canStopPictureInPictureCancellable = nil
    }

    private func setUpViewLayout() {
        #if os(tvOS)
        let canStopPiP = pipController?.canStopPictureInPicture ?? false
        #else
        let canStopPiP = false
        #endif

        // Set up the app's initial buttons.
        updatePiPButtons(canStopPiP: canStopPiP)

        #if os(tvOS)
        // Keep the UI updated.
        canStopPictureInPictureCancellable = pipController?.publisher(for: \.canStopPictureInPicture)
            .sink() { [weak self] in self?.updatePiPButtons(canStopPiP: $0) }
        #endif

        buttonStackView.alignment = .center
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 40

        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.heightAnchor.constraint(equalToConstant: 10),
            progressView.leftAnchor.constraint(equalTo: leftAnchor),
            progressView.rightAnchor.constraint(equalTo: rightAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.heightAnchor.constraint(equalToConstant: 90),
            buttonStackView.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -40),
            buttonStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 60),
            buttonStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -60)
        ])
    }

    private func updatePiPButtons(canStopPiP: Bool) {
        var buttons = [Button]()

        let startButtonTitle = canStopPiP ? "Swap PiP" : "Start PiP"
        let startButtonImage = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: traitCollection)
        let startButton = Button(title: startButtonTitle, image: startButtonImage)
        startButton.addTarget(self, action: #selector(startButtonPressed), for: [.primaryActionTriggered, .touchUpInside])
        buttons.append(startButton)

        if canStopPiP {
            let stopButtonImage = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: traitCollection)
            let stopButton = Button(title: "Stop PiP", image: stopButtonImage)
            stopButton.addTarget(self, action: #selector(stopButtonPressed), for: [.primaryActionTriggered, .touchUpInside])
            buttons.append(stopButton)
        }

        #if os(iOS)
        let closePlayerButton = Button(title: "Close Player", image: UIImage(systemName: "xmark"))
        closePlayerButton.addTarget(self, action: #selector(closePlayerPressed), for: .touchUpInside)
        buttons.append(closePlayerButton)
        #endif

        let existingButtons = buttonStackView.arrangedSubviews
        for view in existingButtons {
            view.removeFromSuperview()
        }
        for button in buttons {
            buttonStackView.addArrangedSubview(button)
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextButton = context.nextFocusedView as? Button {
            nextButton.backgroundColor = .white
            nextButton.tintColor = .darkGray
        }

        if let previousButton = context.previouslyFocusedView as? Button {
            previousButton.backgroundColor = .darkGray
            previousButton.tintColor = .white
        }
    }

    @objc private func startButtonPressed() {
        delegate?.controlsViewDidRequestStartPictureInPicture(self)
    }

    @objc private func stopButtonPressed() {
        delegate?.controlsViewDidRequestStopPictureInPicture(self)
    }

    @objc private func closePlayerPressed() {
        delegate?.controlsViewDidRequestPlayerDismissal(self)
    }

    @objc private func menuGestureHandler(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            delegate?.controlsViewDidRequestControlsDismissal(self)
        default:
            break
        }
    }
}
