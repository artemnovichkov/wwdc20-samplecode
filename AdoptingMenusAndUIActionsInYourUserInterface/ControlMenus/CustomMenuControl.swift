/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example of creating your own menu-based UIControl, showing how to subclass UIControl,
 implementing the UIContextMenuInteractionDelegate protocol, and how to configure and
 update the menu. This control is used in the sample to navigate to each of the demonstration
 view controllers.
*/

import UIKit

class CustomMenuControl: UIControl {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var items: [UIAction] = [] {
        didSet {
            if items.isEmpty {
                self.contextMenuInteraction?.dismissMenu()
                self.isContextMenuInteractionEnabled = false
            } else {
                self.updateMenuIfVisible()
                self.isContextMenuInteractionEnabled = true
            }
        }
    }
    
    var selectedIndex: Int = -1 {
        didSet {
            self.updateMenuIfVisible()
        }
    }
    
    var showSelectedItem: Bool = true {
        didSet {
            self.updateMenuIfVisible()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.titleLabel.isHighlighted = self.isHighlighted
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        titleLabel.textColor = self.tintColor
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.tintColor
        label.highlightedTextColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16.0),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.heightAnchor.constraint(greaterThanOrEqualTo: label.heightAnchor),
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0)
        ])
        return label
    }()
    
    func configureBackground(highlighted: Bool) {
        self.backgroundColor = highlighted ? .systemGray2 : .systemGray5
        self.layer.cornerRadius = highlighted ? 8.0 : 16.0
        self.layer.cornerCurve = .continuous
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsMenuAsPrimaryAction = true
        configureBackground(highlighted: false)
        self.titleLabel.text = "Title"
    }

    convenience init(frame: CGRect, primaryAction: UIAction?) {
        self.init(frame: frame)
        if let primaryAction = primaryAction {
            self.addAction(primaryAction, for: .primaryActionTriggered)
            self.titleLabel.text = primaryAction.title
        }
    }
    
    func updateMenuIfVisible() {
        self.contextMenuInteraction?.updateVisibleMenu { [unowned self] _ in
            return self.menu
        }
    }
    
    func proxyAction(_ action: UIAction, selected: Bool) -> UIAction {
        let proxy = UIAction(title: action.title,
                             image: action.image,
                             discoverabilityTitle: action.discoverabilityTitle,
                             attributes: action.attributes,
                             state: selected ? .on : .off) { proxy in
            guard let control = proxy.sender as? CustomMenuControl else { return }
            control.selectedIndex = control.items.firstIndex(of: action) ?? -1
            control.sendAction(action)
            control.sendActions(for: .primaryActionTriggered)
        }
        return proxy
    }
    
    var menu: UIMenu {
        let selectedAction: UIAction?
        if showSelectedItem && selectedIndex >= 0 && selectedIndex < items.count {
            selectedAction = items[selectedIndex]
        } else {
            selectedAction = nil
        }
        return UIMenu(title: "", children: items.map {
            return proxyAction($0, selected: $0 == selectedAction)
        })
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [unowned self] _ -> UIMenu? in
            self.menu
        }
    }
    
    func previewForMenuPresentation() -> UITargetedPreview {
        let previewTarget = UIPreviewTarget(container: titleLabel, center: titleLabel.center)
        let previewParameters = UIPreviewParameters()
        previewParameters.backgroundColor = .clear
        return UITargetedPreview(view: UIView(frame: titleLabel.frame), parameters: previewParameters, target: previewTarget)
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         previewForHighlightingMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
        return previewForMenuPresentation()
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         previewForDismissingMenuWithConfiguration config: UIContextMenuConfiguration) -> UITargetedPreview? {
        return previewForMenuPresentation()
    }
    
    func animateBackgroundHighlight(_ animator: UIContextMenuInteractionAnimating?, highlighted: Bool) {
        if let animator = animator {
            animator.addAnimations {
                self.configureBackground(highlighted: highlighted)
            }
        } else {
            configureBackground(highlighted: highlighted)
        }
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willDisplayMenuFor config: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: config, animator: animator)
        animateBackgroundHighlight(animator, highlighted: true)
    }
    
    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                         willEndFor config: UIContextMenuConfiguration,
                                         animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willEndFor: config, animator: animator)
        animateBackgroundHighlight(animator, highlighted: false)
    }
    
}
