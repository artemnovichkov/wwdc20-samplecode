/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Shows how you can now update the menu presented by a UIContextMenuInteraction,
 and how you can adapt the menu based on how it is presented.
*/

import UIKit

class UpdateMenuViewController: UIViewController, UIContextMenuInteractionDelegate {

    func demoImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: "shield.fill"))
        imageView.isUserInteractionEnabled = true
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 288.0)
        return imageView
    }
    
    var contextMenuInteraction: UIContextMenuInteraction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "Updating Menu"

        let imageView = demoImageView()
        contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        imageView.addInteraction(contextMenuInteraction)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if interaction.menuAppearance == .rich {
            // For a rich presentation, we'll use a shorter menu and configure the preview
            return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
                let viewController = UIViewController()
                let imageView = self.demoImageView()
                viewController.view = imageView
                viewController.preferredContentSize = imageView.sizeThatFits(.zero)
                return viewController
            } actionProvider: { _ -> UIMenu? in
                return UIMenu(title: "", children: [
                    UIAction(title: "Item 1", image: UIImage(systemName: "mic"), handler: { _ in }),
                    UIAction(title: "Item 2", image: UIImage(systemName: "message"), handler: { _ in }),
                    UIAction(title: "Item 3", image: UIImage(systemName: "envelope"), handler: { _ in }),
                    UIAction(title: "Item 4", image: UIImage(systemName: "phone"), handler: { _ in }),
                    UIAction(title: "Item 5", image: UIImage(systemName: "video"), handler: { _ in })
                ])
            }
        } else {
            // For a compact presentation, we focus on the menu, but add additional actions
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
                return UIMenu(title: "", children: [
                    UIAction(title: "Item 1", image: UIImage(systemName: "mic"), handler: { _ in }),
                    UIAction(title: "Item 2", image: UIImage(systemName: "message"), handler: { _ in }),
                    UIAction(title: "Item 3", image: UIImage(systemName: "envelope"), handler: { _ in }),
                    UIAction(title: "Item 4", image: UIImage(systemName: "phone"), handler: { _ in }),
                    UIAction(title: "Item 5", image: UIImage(systemName: "video"), handler: { _ in }),
                    UIMenu(title: "", options: .displayInline, children: [
                        UIAction(title: "Compact-only Item 1", image: UIImage(systemName: "mic"), handler: { _ in }),
                        UIAction(title: "Compact-only Item 2", image: UIImage(systemName: "message"), handler: { _ in }),
                        UIAction(title: "Compact-only Item 3", image: UIImage(systemName: "envelope"), handler: { _ in }),
                        UIAction(title: "Compact-only Item 4", image: UIImage(systemName: "phone"), handler: { _ in }),
                        UIAction(title: "Compact-only Item 5", image: UIImage(systemName: "video"), handler: { _ in })
                    ])
                ])
            }
        }
    }
    
    var timer: Timer? = nil
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { [unowned self] _ in
            self.contextMenuInteraction.updateVisibleMenu { currentMenu -> UIMenu in
                currentMenu.children.forEach { element in
                    guard let action = element as? UIAction else { return }
                    
                    action.state = Bool.random() ? .off : .on
                    action.attributes = Bool.random() ? [.hidden] : []
                }
                return currentMenu
            }
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {
        timer?.invalidate()
        timer = nil
    }
    
}
