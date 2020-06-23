/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's primary view controller.
*/

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customMenuControl = CustomMenuControl(frame: .zero, primaryAction: UIAction(title: "Demo Selector", handler: { _ in }))
        customMenuControl.showSelectedItem = false
        customMenuControl.items = [
            UIAction(title: "Button Demo", handler: { [unowned self] _ in
                let demo = ButtonMenuDemoViewController()
                self.navigationController?.pushViewController(demo, animated: true)
            }),
            UIAction(title: "Bar Button Item Demo", handler: { [unowned self] _ in
                let demo = BarButtonItemDemoViewController()
                self.navigationController?.pushViewController(demo, animated: true)
            }),
            UIAction(title: "Back Button Demo", handler: { [unowned self] _ in
                func makeViewController(_ level: Int) -> UIViewController {
                    let viewController = UIViewController()
                    viewController.title = "Level \(level)"
                    viewController.navigationItem.backButtonTitle = "\(level)"
                    viewController.view.backgroundColor = .systemBackground
                    return viewController
                }
                for level in 1..<10 {
                    self.navigationController?.pushViewController(makeViewController(level), animated: false)
                }
                self.navigationController?.pushViewController(makeViewController(10), animated: true)
            }),
            UIAction(title: "Segmented Control Demo", handler: { [unowned self] _ in
                let demo = SegmentedControlDemoViewController()
                self.navigationController?.pushViewController(demo, animated: true)
            }),
            UIAction(title: "Deferred Element Demo", handler: { [unowned self] _ in
                let demo = DeferredMenuElementDemoViewController()
                self.navigationController?.pushViewController(demo, animated: true)
            }),
            UIAction(title: "Update Menu Demo", handler: { [unowned self] _ in
                let demo = UpdateMenuViewController()
                self.navigationController?.pushViewController(demo, animated: true)
            })
        ]
        customMenuControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customMenuControl)
        
        NSLayoutConstraint.activate([
            customMenuControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customMenuControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40.0)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

}

