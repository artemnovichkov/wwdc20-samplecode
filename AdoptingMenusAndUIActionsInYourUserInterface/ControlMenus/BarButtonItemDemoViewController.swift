/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Shows off new API for creating UIBarButtonItems with UIActions and UIMenus,
 as well as new conveniences for creating fixed & flexible spaces.
*/

import UIKit

class BarButtonItemDemoViewController: UIViewController {

    let eventExplainer = UILabel()
    func showExplainer(_ text: String) {
        eventExplainer.text = text
        UIView.animateKeyframes(withDuration: 1.0, delay: 0.0, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                self.eventExplainer.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                self.eventExplainer.alpha = 0.0
            }
        } completion: { _ in
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "UIBarButtonItem"

        eventExplainer.translatesAutoresizingMaskIntoConstraints = false
        eventExplainer.text = "PH"
        eventExplainer.alpha = 0.0
        view.addSubview(eventExplainer)

        NSLayoutConstraint.activate([
            eventExplainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            eventExplainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0)
        ])

        func menuHandler(action: UIAction) {
            showExplainer("Menu Action '\(action.title)'")
        }
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
                            menu: UIMenu(title: "",
                                         children: (1...5).map { UIAction(title: "Option \($0)", handler: menuHandler) })),
            UIBarButtonItem(systemItem: .action,
                            primaryAction: UIAction(title: "", handler: { [unowned self] action in self.showExplainer("Action Bar Button") }),
                            menu: UIMenu(title: "",
                                         children: (1...5).map { UIAction(title: "Action \($0)", handler: menuHandler) }))
        ]
        
        let saveAction = UIAction(title: "", handler: menuHandler)
        let saveMenu = UIMenu(title: "", children: [
            UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: menuHandler),
            UIAction(title: "Rename", image: UIImage(systemName: "pencil"), handler: menuHandler),
            UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.on.square"), handler: menuHandler),
            UIAction(title: "Move", image: UIImage(systemName: "folder"), handler: menuHandler)
        ])
        let optionsImage = UIImage(systemName: "ellipsis.circle")
        let optionsMenu = UIMenu(title: "", children: [
            UIAction(title: "Info", image: UIImage(systemName: "info.circle"), handler: menuHandler),
            UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), handler: menuHandler),
            UIAction(title: "Collaborate", image: UIImage(systemName: "person.crop.circle.badge.plus"), handler: menuHandler)
        ])
        let revertAction = UIAction(title: "Revert", handler: menuHandler)
        self.toolbarItems = [
            UIBarButtonItem(systemItem: .save, primaryAction: saveAction, menu: saveMenu),
            .fixedSpace(width:20.0),
            UIBarButtonItem(image: optionsImage, menu: optionsMenu),
            .flexibleSpace(),
            UIBarButtonItem(primaryAction: revertAction)
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
}
