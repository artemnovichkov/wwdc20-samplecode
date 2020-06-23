/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DebugSettingsViewController
*/

import os.log
import UIKit

class DebugSettingsViewController: UITableViewController {

    public var onDismissComplete: (() -> Void)?

    private var completionCalled = false

    var settings: DebugSettings {
        return DebugSettings.shared
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        completionCalled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let completion = onDismissComplete else {
            fatalError("must set callback for onDismissComplete")
        }
        if !completionCalled {
            completion()
            completionCalled = true
        }
    }

    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        guard let completion = onDismissComplete else {
            fatalError("must set callback for onDismissComplete")
        }
        // hold a strong reference until completion is called
        let viewController = self
        dismiss(animated: true) {
            if !viewController.completionCalled {
                DispatchQueue.main.async {
                    completion()
                    viewController.completionCalled = true
                }
            }
        }
    }

    @IBAction func resetButtonTriggered(_ sender: UIBarButtonItem) {
        let changed = settings.resetToDefaults()
        changed.forEach {
            guard let value = $0.kind.value,
            let onDidChange = $0.valueDidChange else { return }
            _ = onDidChange(value)
        }
        tableView.reloadData()
    }

}

extension DebugSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.prototypes(in: section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let label = settings.section(section).kind.label ?? ""
        return label.isEmpty ? nil : label
    }

    private func getterSetterCell<T: DebugSettingsCell>(identifier: String, cellForRowAt indexPath: IndexPath) -> T {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            return T()
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let prototype = settings.prototype(indexPath)

        let cell: DebugSettingsCell
        switch prototype.kind {
        case .switchBool:
            let typedCell: DebugSettingsSwitchCell = getterSetterCell(identifier: "SWITCH", cellForRowAt: indexPath)
            cell = typedCell
        case .buttonBool:
            let typedCell: DebugSettingsButtonCell = getterSetterCell(identifier: "BUTTON", cellForRowAt: indexPath)
            cell = typedCell
        case .sliderInt:
            let typedCell: DebugSettingsSliderCell = getterSetterCell(identifier: "SLIDER", cellForRowAt: indexPath)
            cell = typedCell
        case .sliderFloat:
            let typedCell: DebugSettingsSliderCell = getterSetterCell(identifier: "SLIDER", cellForRowAt: indexPath)
            cell = typedCell
        case .buttonEnum:
            let typedCell: DebugSettingsButtonCell = getterSetterCell(identifier: "BUTTON", cellForRowAt: indexPath)
            cell = typedCell
        case .section:
            let typedCell: DebugSettingsSectionCell = getterSetterCell(identifier: "SECTION", cellForRowAt: indexPath)
            cell = typedCell
        }
        cell.tableView = tableView
        cell.release = prototype.controlWasReleased
        cell.prototype = prototype

        return cell
    }

    // Select row...
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // don't leave row selected
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
