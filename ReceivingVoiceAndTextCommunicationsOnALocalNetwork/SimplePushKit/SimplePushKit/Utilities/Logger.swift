/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Logger' is a wrapper around `OSLog` for logging application events.
*/

import Foundation
import os

public class Logger {
    public enum Subsystem: String {
        case general
        case networking
        case heartbeat
        case callKit
    }
    
    private var prependString: String
    private var osLog: OSLog
    
    public init(prependString: String, subsystem: Subsystem) {
        self.prependString = prependString
        let bundleID = Bundle(for: type(of: self)).bundleIdentifier ?? "com.simplepush"
        self.osLog = OSLog(subsystem: bundleID + "." + subsystem.rawValue, category: "Debug")
    }
    
    public func log(_ message: String) {
        os_log("%@: %@", log: osLog, type: .default, prependString, message)
    }
}
