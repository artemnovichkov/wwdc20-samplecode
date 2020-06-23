/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DebugSettingsCell
*/

import UIKit

class DebugSettingsCell: UITableViewCell {
    weak var tableView: UITableView?
    var prototype: DebugSettingPrototype?
    var release: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        release = nil
        prototype = nil
        setSelected(false, animated: false)
    }

    open func refresh() {
        fatalError("never should be called - overridden by subclasses")
    }
}

// MARK: -

class DebugSettingsSwitchCell: DebugSettingsCell {

    override var prototype: DebugSettingPrototype? {
        didSet { refresh() }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var uiSwitch: UISwitch!

    override func refresh() {
        guard let prototype = prototype,
        let value = prototype.kind.value as? Bool else {
            return
        }
        titleLabel.text = prototype.kind.label
        uiSwitch.isOn = value
    }

    @IBAction func switchDidChange(_ sender: UISwitch) {
        guard var prototype = prototype, prototype.kind.value as? Bool != nil else {
            return
        }
        let newValue = uiSwitch.isOn
        prototype.kind.value = newValue
        if prototype.valueDidChange?(newValue) ?? false {
            tableView?.reloadData()
        }
    }
}

// MARK: -

class DebugSettingsSliderCell: DebugSettingsCell {
    var step: Float?

    private func setTextField(_ newValue: Float) {
        guard let prototype = prototype else { return }
        textField.text = prototype.kind.valueType == Float.self ? String(newValue) : String(Int(newValue))
    }

    override var prototype: DebugSettingPrototype? {
        didSet { refresh() }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!

    override func refresh() {
        guard let prototype = prototype,
        let value = prototype.kind.value else { return }

        let floatValue: Float
        if prototype.kind.valueType == Float.self {
            guard let tempValue = value as? Float else { return }
            floatValue = tempValue
        } else {
            guard let tempValue = value as? Int else { return }
            floatValue = Float(tempValue)
        }
        titleLabel.text = prototype.kind.label
        setTextField(floatValue)
        switch prototype.kind {
        case let .sliderInt(setting):
            slider.minimumValue = Float(setting.minimum ?? 0)
            slider.maximumValue = Float(setting.maximum ?? 0)
            if let step = setting.step {
                self.step = Float(step)
            }
        case let .sliderFloat(setting):
            slider.minimumValue = setting.minimum ?? 0.0
            slider.maximumValue = setting.maximum ?? 0.0
            if let step = setting.step {
                self.step = step
            }
        default: break
        }
        slider.value = floatValue
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        guard var prototype = prototype,
        let textValue = textField.text,
        var newValue = Float(textValue) else {
            return
        }
        if newValue < slider.minimumValue {
            newValue = slider.minimumValue
            setTextField(newValue)
        } else if newValue > slider.maximumValue {
            newValue = slider.maximumValue
            setTextField(newValue)
        } else if let stepValue = step {
            newValue = round(newValue / stepValue) * stepValue
            setTextField(newValue)
        }
        if prototype.kind.valueType == Float.self {
            prototype.kind.value = newValue
        } else {
            prototype.kind.value = Int(newValue)
        }
        slider.value = newValue
        if prototype.valueDidChange?(newValue) ?? false {
            tableView?.reloadData()
        }
    }

    @IBAction func sliderDidChange(_ sender: UISlider) {
        guard var prototype = prototype else { return }
        var newValue = sender.value
        if let stepValue = step {
            newValue = round(newValue / stepValue) * stepValue
            sender.value = newValue
        }
        setTextField(newValue)
        if prototype.kind.valueType == Float.self {
            prototype.kind.value = newValue
            if prototype.valueDidChange?(newValue) ?? false {
                tableView?.reloadData()
            }
        } else {
            let value = Int(newValue)
            prototype.kind.value = value
            if prototype.valueDidChange?(value) ?? false {
                tableView?.reloadData()
            }
        }
    }

    @IBAction func sliderDidRelease(_ sender: UISlider) {
        release?()
    }
}

// MARK: -

class DebugSettingsButtonCell: DebugSettingsCell {
    private func updateButtonUI() {
        guard let prototype = prototype else { return }
        guard let value = prototype.kind.value else { return }
        let intValue: Int
        if prototype.kind.valueType == Int.self {
            guard let tempValue = value as? Int else { return }
            intValue = tempValue
        } else {
            guard let tempValue = value as? Bool else { return }
            intValue = tempValue ? 1 : 0
        }

        if let imageNames = prototype.kind.imageNames {
            var index = intValue
            if index >= imageNames.count {
                index = 0
            }
            var uiImage = UIImage(systemName: imageNames[index])
            if uiImage == nil {
                uiImage = UIImage(named: imageNames[index])
            }
            uiButton.setImage(uiImage, for: .normal)
        }

        guard let titles = prototype.kind.titles,
        intValue >= 0,
        intValue < titles.count else {
            uiButton.setTitle(prototype.kind.titles?.first, for: .normal)
            return
        }
        uiButton.setTitle(titles[intValue], for: .normal)
    }

    override var prototype: DebugSettingPrototype? {
        didSet { refresh() }
    }

    override func refresh() {
        guard let prototype = prototype else {
            return
        }
        updateButtonUI()
        titleLabel.text = prototype.kind.label
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var uiButton: UIButton!

    @IBAction func buttonWasPressed(_ sender: UIButton) {
        guard var prototype = prototype else { return }
        switch prototype.kind {
        case .buttonBool:
            guard var value = prototype.kind.value as? Bool else { return }
            value.toggle()
            prototype.kind.value = value
            updateButtonUI()
            if prototype.valueDidChange?(value) ?? false {
                tableView?.reloadData()
            }

        case .buttonEnum(let setting):
            guard var value = prototype.kind.value as? Int,
            let titles = prototype.kind.titles else { return }

            value += setting.step ?? 1
            if value >= titles.count {
                value = 0
            }
            prototype.kind.value = value
            updateButtonUI()
            if prototype.valueDidChange?(value) ?? false {
                tableView?.reloadData()
            }

        default: fatalError("Button for buttonEnum was pressed but prototype kind is not correct")
        }
    }
}

class DebugSettingsSectionCell: DebugSettingsCell {
    override var prototype: DebugSettingPrototype? {
        didSet { refresh() }
    }

    override func refresh() {
        guard let prototype = prototype else {
            return
        }
        titleLabel?.text = prototype.kind.label

    }

    @IBOutlet var titleLabel: UILabel!
}
