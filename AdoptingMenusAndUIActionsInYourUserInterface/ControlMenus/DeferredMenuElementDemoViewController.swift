/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Provides an example of the new UIDeferredMenuElement,
 useful for augmenting a menu asynchronously from its presentation.
*/

import UIKit

class DeferredMenuElementDemoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "UIDeferredMenuElement"
        
        let button = UIButton(primaryAction: UIAction(title: "Menu Button", handler: { _ in }))
        button.menu = UIMenu(title: "", children: [
            UIMenu(title: "", options: .displayInline, children: (1...2).map { UIAction(title: "Static Item \($0)") { action in } }),
            UIDeferredMenuElement({ completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let items = (1...2).map { UIAction(title: "Dynamic Item \($0)") { action in } }
                    completion([UIMenu(title: "", options: .displayInline, children: items)])
                }
            })
        ])
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0)
        ])
    }

}
