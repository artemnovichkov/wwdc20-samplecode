#!/usr / bin / swift
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Command-line tool for preprocessing audio resources.
*/

// AUSampler preset files refer to the path on disk where they are located on the Mac that created them.
// This script translates the path into a generic /Library/Audio/Sounds path that works with the AUSampler
// on iOS.

import Foundation

if CommandLine.argc < 3 {
    print("Usage: clean_preset <path/to/input_preset> <path/to/output_preset>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard FileManager.default.fileExists(atPath: inputPath) else {
    fatalError("File not found: \(inputPath)")
}

let inputURL = URL(fileURLWithPath: inputPath)
let outputURL = URL(fileURLWithPath: outputPath)

var plist: [String: Any]?

do {
    let plistData = try Data(contentsOf: inputURL)
    plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
} catch {
    print("Failed to read input file: \(inputPath)")
    fatalError("Error: \(error)")
}

guard var plist = plist else {
    fatalError("Failed to read input file: \(inputPath)")
}

guard var fileRefs = plist["file-references"] as? [String: NSString] else {
    fatalError("expected 'file-references' in preset plist")
}

for (key, value) in fileRefs {
    let newPath = "/Library/Audio/Sounds/\(value.lastPathComponent)"
    fileRefs[key] = NSString(string: newPath)
}

// replace the file references with our updated dictionary
plist["file-references"] = fileRefs

do {
    let outputData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try outputData.write(to: outputURL)
    print("Wrote output to: \(outputPath)")
} catch {
    fatalError("Error: \(error)")
}

