/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Model types representing illustration shapes and files.
*/

import UIKit

class Shape {
    enum Style: Int {
        case rectangle
        case circle
    }
    
    var rect: CGRect
    var style: Style
    var color: UIColor
    
    init(rect: CGRect, style: Style, color: UIColor) {
        self.rect = rect
        self.style = style
        self.color = color
    }
}

class IllustrationFile {
    var name: String
    var shapes: [Shape] = []
    var identifier: Int
    
    init(withName name: String, identifier: Int) {
        self.name = name
        self.identifier = identifier
    }
}

struct FileStore {
    var files: [IllustrationFile]
    
    static func untitledNameForIdentifier(_ identifier: Int) -> String {
        let fileNameFormatString = NSLocalizedString("UNTITLED_%d", comment: "Untitled filename")
        return String(format: fileNameFormatString, identifier)
    }
    
    init() {
        // As an example, just initialize in memory with a list of empty files.
        var files: [IllustrationFile] = []
        
        for identifier in 0...8 {
            let fileName = FileStore.untitledNameForIdentifier(identifier)
            let file = IllustrationFile(withName: fileName, identifier: identifier)
            files.append(file)
        }
        
        self.files = files
    }
    
    public func itemForIdentifier(_ identifier: Int) -> IllustrationFile? {
        return files.first(where: { $0.identifier == identifier })
    }
    
    public func allIdentifiers() -> [Int] {
        return files.map { $0.identifier }
    }
    
    public mutating func createNewFile() -> IllustrationFile {
        let nextIdentifier = (files.last?.identifier ?? 0) + 1
        let fileName = FileStore.untitledNameForIdentifier(nextIdentifier)
        let newFile = IllustrationFile(withName: fileName, identifier: nextIdentifier)
        files.append(newFile)
        
        return newFile
    }
    
    public mutating func deleteItemWithIdentifier(_ identifier: Int) {
        if let index = files.firstIndex(where: { $0.identifier == identifier }) {
            files.remove(at: index)
        }
    }
}
