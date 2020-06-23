/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Demonstrates creating UIButtons that present menus, on touch down or long press.
*/

import UIKit

class ButtonMenuDemoViewController: UIViewController {

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
        self.title = "UIButton"
        
        eventExplainer.translatesAutoresizingMaskIntoConstraints = false
        eventExplainer.text = "PH"
        eventExplainer.alpha = 0.0
        view.addSubview(eventExplainer)

        let button = UIButton(primaryAction: UIAction(title: "Menu Button", handler: { [unowned self] _ in self.showExplainer("Button Triggered") }))
        button.addAction(UIAction(title: "", handler: { [unowned self] _ in self.showExplainer("Menu Triggered") }), for: .menuActionTriggered)
        let items = (1...5).map { UIAction(title: $0.description) { [unowned self] action in self.showExplainer("Menu Action '\(action.title)'") } }
        button.menu = UIMenu(title: "", children: items)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = false
        view.addSubview(button)
        
        let swtch = UISwitch(frame: .zero, primaryAction: UIAction(title: "", handler: { [unowned button] action in
            guard let swtch = action.sender as? UISwitch else { return }
            button.showsMenuAsPrimaryAction = swtch.isOn
        }))
        swtch.isOn = button.showsMenuAsPrimaryAction
        let label = UILabel()
        label.text = ".showsMenuAsPrimaryAction = "
        let stack = UIStackView(arrangedSubviews: [label, swtch])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0),
            eventExplainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            eventExplainer.topAnchor.constraint(equalTo: swtch.bottomAnchor, constant: 20.0),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: eventExplainer.bottomAnchor, constant: 20.0)
        ])
    }

}
