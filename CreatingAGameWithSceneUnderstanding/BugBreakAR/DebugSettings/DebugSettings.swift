/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Debug Settings
*/

import os.log
import UIKit

private let log = OSLog(subsystem: appSubsystem, category: "DebugSettings")

// Debug Settings can be Bool, Float, Int

public protocol DebugSettingProtocol: AnyObject {
    associatedtype DataType
    var value: DataType { get set }
    var defaultValue: DataType { get }
    var label: String? { get }
    var imageNames: [String]? { get }
    var titles: [String]? { get }
    var minimum: DataType? { get }
    var maximum: DataType? { get }
    var step: DataType? { get }
}

public class DebugSettingBool: DebugSettingProtocol {
    public typealias DataType = Bool
    public var value: DataType
    public private(set) var defaultValue: DataType
    public fileprivate(set) var label: String?
    public fileprivate(set) var imageNames: [String]?
    public private(set) var titles: [String]?
    public private(set) var minimum: DataType?
    public private(set) var maximum: DataType?
    public private(set) var step: DataType?

    public init(_ defaultValue: DataType,
                label: String? = nil,
                imageNames: [String]? = nil) {
        self.defaultValue = defaultValue
        self.label = label
        self.imageNames = imageNames
        self.value = defaultValue
    }
}

public class DebugSettingInt: DebugSettingProtocol {
    public typealias DataType = Int
    public var value: DataType
    public private(set) var defaultValue: DataType
    public fileprivate(set) var label: String?
    public fileprivate(set) var imageNames: [String]?
    public private(set) var titles: [String]?
    public private(set) var minimum: DataType?
    public private(set) var maximum: DataType?
    public private(set) var step: DataType?

    public init(_ defaultValue: DataType,
                label: String? = nil,
                minimum: DataType? = nil, maximum: DataType? = nil, step: DataType? = nil) {
        self.defaultValue = defaultValue
        self.label = label
        self.minimum = minimum ?? defaultValue
        self.maximum = maximum ?? defaultValue
        self.step = step ?? 1
        self.value = defaultValue
    }
}

public class DebugSettingFloat: DebugSettingProtocol {
    public typealias DataType = Float
    public var value: DataType
    public private(set) var defaultValue: DataType
    public fileprivate(set) var label: String?
    public fileprivate(set) var imageNames: [String]?
    public private(set) var titles: [String]?
    public private(set) var minimum: DataType?
    public private(set) var maximum: DataType?
    public private(set) var step: DataType?

    public init(_ defaultValue: DataType,
                label: String? = nil,
                minimum: DataType? = nil, maximum: DataType? = nil, step: DataType? = nil) {
        self.defaultValue = defaultValue
        self.label = label
        self.minimum = minimum ?? defaultValue
        self.maximum = maximum ?? defaultValue
        self.step = step
        self.value = defaultValue
    }
}

public class DebugSettingEnum: DebugSettingProtocol {
    public typealias DataType = Int
    public var value: DataType
    public private(set) var defaultValue: DataType
    public fileprivate(set) var label: String?
    public fileprivate(set) var imageNames: [String]?
    public private(set) var titles: [String]?
    public private(set) var minimum: DataType?
    public private(set) var maximum: DataType?
    public private(set) var step: DataType?

    public init(_ defaultValue: DataType,
                label: String? = nil,
                imageNames: [String]? = nil,
                titles: [String]) {
        self.defaultValue = defaultValue
        self.imageNames = imageNames
        self.label = label
        self.titles = titles
        self.value = defaultValue
    }
}

class DebugSettings {
    static let shared = DebugSettings()

    private var sections: [DebugSettingPrototype] = []
    private var prototypes: [[DebugSettingPrototype]] = [[]]

    public var numberOfSections: Int { return sections.count }

    func section(_ section: Int) -> DebugSettingPrototype {
        return sections[section]
    }

    func prototype(_ indexPath: IndexPath) -> DebugSettingPrototype {
        return prototypes[indexPath.section][indexPath.row]
    }

    func prototypes(in section: Int) -> Int {
        return prototypes[section].count
    }

    private func sectionPrototypes(_ newPrototypes: [DebugSettingPrototype]) {
        var prototypeCount: Int = 0
        prototypes = [[]]
        sections = []
        newPrototypes.forEach { prototype in
            if case .section = prototype.kind {
                if !sections.isEmpty {
                    prototypes.append([])
                }
                sections.append(prototype)
                return
            }
            if sections.isEmpty {
                sections.append(DebugSettingPrototype(.section("")))
            }
            prototypes[sections.count - 1].append(prototype)
            prototypeCount += 1
        }
        log.debug("%d prototypeCount added in %d sections", prototypeCount, sections.count)
    }

    func newPrototypes(_ prototypes: [DebugSettingPrototype]) {
        sectionPrototypes(prototypes)
    }

    public func resetToDefaults() -> [DebugSettingPrototype] {
        var changed = [DebugSettingPrototype]()
        prototypes
            .flatMap { $0 }
            .forEach {
                if !$0.kind.isDefaultValue {
                    $0.kind.setDefaultValue()
                    changed.append($0)
                }
            }
        return changed
    }
}
