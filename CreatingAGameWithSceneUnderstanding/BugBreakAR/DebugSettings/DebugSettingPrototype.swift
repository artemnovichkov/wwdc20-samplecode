/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DebugSettings
*/

import os.log

struct DebugSettingPrototype {

    private let log = OSLog(subsystem: appSubsystem, category: "DebugSettingPrototype")

    enum Kind {
        case switchBool(DebugSettingBool)
        case buttonBool(DebugSettingBool)
        case sliderInt(DebugSettingInt)
        case sliderFloat(DebugSettingFloat)
        case buttonEnum(DebugSettingEnum)
        case section(String)
    }

    var kind: Kind
    let sampleCode: Bool
    var controlWasReleased: (() -> Void)?
    var valueDidChange: ((Any) -> Bool)?

    // action, seque, section
    init(sampleCode: Bool = true, _ kind: Kind) {
        self.kind = kind
        self.sampleCode = sampleCode
    }

    init(sampleCode: Bool = true, _ setting: DebugSettingBool, _ completion: ((Bool) -> Bool)? = nil) {
        if setting.imageNames != nil {
            kind = .buttonBool(setting)
        } else {
            kind = .switchBool(setting)
        }
        self.sampleCode = sampleCode
        self.valueDidChange = { newValue in
            guard let value = newValue as? Bool else { return false }
            return completion?(value) ?? false
        }
    }

    init(sampleCode: Bool = true, _ setting: DebugSettingInt, _ completion: ((Int) -> Bool)? = nil) {
        self.kind = .sliderInt(setting)
        self.sampleCode = sampleCode
        self.valueDidChange = { newValue in
            guard let value = newValue as? Int else { return false }
            return completion?(value) ?? false
        }
    }

    init(sampleCode: Bool = true, _ setting: DebugSettingFloat, _ completion: ((Float) -> Bool)? = nil) {
        self.kind = .sliderFloat(setting)
        self.sampleCode = sampleCode
        self.valueDidChange = { newValue in
            guard let value = newValue as? Float else { return false }
            return completion?(value) ?? false
        }
    }

    init(sampleCode: Bool = true, _ setting: DebugSettingEnum, _ completion: ((Int) -> Bool)? = nil) {
        self.kind = .buttonEnum(setting)
        self.sampleCode = sampleCode
        self.valueDidChange = { newValue in
            guard let value = newValue as? Int else { return false }
            return completion?(value) ?? false
        }
    }

    public func printDetails(_ prefix: String) {
        let label = kind.label ?? "no label"
        let value = kind.value ?? "nil value"
        let defaultValue = kind.defaultValue ?? "nil default value"
        log.debug("%s %s-'%s' = %s/%s", "\(prefix)", "\(kind)", "\(label)", "\(value)", "\(defaultValue)")
    }
}

extension DebugSettingPrototype.Kind {
    var hasKeyValue: Bool {
        switch self {
        case .switchBool, .buttonBool:
            return true
        case .sliderInt, .sliderFloat:
            return true
        case .buttonEnum:
            return true
        case .section:
            return false
        }
    }

    var label: String? {
        switch self {
        case .switchBool(let setting):
            return setting.label
        case .buttonBool(let setting):
            return setting.label
        case .sliderInt(let setting):
            return setting.label
        case .sliderFloat(let setting):
            return setting.label
        case .buttonEnum(let setting):
            return setting.label
        case .section(let label):
            return label
        }
    }

    var imageNames: [String]? {
        switch self {
        case .switchBool(let setting):
            return setting.imageNames
        case .buttonBool(let setting):
            return setting.imageNames
        case .sliderInt(let setting):
            return setting.imageNames
        case .sliderFloat(let setting):
            return setting.imageNames
        case .buttonEnum(let setting):
            return setting.imageNames
        case .section:
            return nil
        }
    }

    var titles: [String]? {
        switch self {
        case .switchBool(let setting):
            return setting.titles
        case .buttonBool(let setting):
            return setting.titles
        case .sliderInt(let setting):
            return setting.titles
        case .sliderFloat(let setting):
            return setting.titles
        case .buttonEnum(let setting):
            return setting.titles
        case .section:
            return nil
        }
    }

    var valueType: Any.Type? {
        switch self {
        case .switchBool, .buttonBool:
            return Bool.self
        case .sliderInt:
            return Int.self
        case .sliderFloat:
            return Float.self
        case .buttonEnum:
            return Int.self
        case .section:
            return nil
        }
    }

    var defaultValue: Any? {
        switch self {
        case .switchBool(let setting):
            return setting.defaultValue
        case .buttonBool(let setting):
            return setting.defaultValue
        case .sliderInt(let setting):
            return setting.defaultValue
        case .sliderFloat(let setting):
            return setting.defaultValue
        case .buttonEnum(let setting):
            return setting.defaultValue
        case .section:
            return nil
        }
    }

    var value: Any? {
        get {
            switch self {
            case .switchBool(let setting):
                return setting.value
            case .buttonBool(let setting):
                return setting.value
            case .sliderInt(let setting):
                return setting.value
            case .sliderFloat(let setting):
                return setting.value
            case .buttonEnum(let setting):
                return setting.value
            case .section:
                return nil
            }
        }
        set {
            switch self {
            case .switchBool(let setting):
                guard let value = newValue as? Bool else { return }
                setting.value = value
            case .buttonBool(let setting):
                guard let value = newValue as? Bool else { return }
                setting.value = value
            case .sliderInt(let setting):
                guard let value = newValue as? Int else { return }
                setting.value = value
            case .sliderFloat(let setting):
                guard let value = newValue as? Float else { return }
                setting.value = value
            case .buttonEnum(let setting):
                guard let value = newValue as? Int else { return }
                setting.value = value
            case .section:
                break
            }
        }
    }

    var isDefaultValue: Bool {
        switch self {
        case .switchBool(let setting):
            return setting.value == setting.defaultValue
        case .buttonBool(let setting):
            return setting.value == setting.defaultValue
        case .sliderInt(let setting):
            return setting.value == setting.defaultValue
        case .sliderFloat(let setting):
            return setting.value == setting.defaultValue
        case .buttonEnum(let setting):
            return setting.value == setting.defaultValue
        case .section:
            break
        }
        return false
    }

    func setDefaultValue() {
        switch self {
        case .switchBool(let setting):
            setting.value = setting.defaultValue
        case .buttonBool(let setting):
            setting.value = setting.defaultValue
        case .sliderInt(let setting):
            setting.value = setting.defaultValue
        case .sliderFloat(let setting):
            setting.value = setting.defaultValue
        case .buttonEnum(let setting):
            setting.value = setting.defaultValue
        case .section:
            break
        }
    }
}
