/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom NWProtocolFramerImplementation that encodes/decodes using a prepended messsage length header.
*/

import Foundation
import Network

public class LengthPrefixedFramer: NWProtocolFramerImplementation {
    private typealias Header = UInt32
    
    public static let label = "LengthPrefixedFramer"
    public static let definition = NWProtocolFramer.Definition(implementation: LengthPrefixedFramer.self)
    private let logger = Logger(prependString: "LengthPrefixedFramer", subsystem: .networking)
    
    public required init(framer: NWProtocolFramer.Instance) {}
    
    public func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult {
        .ready
    }
    
    public func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        let headerSize = MemoryLayout<Header>.size
        
        while true {
            var header: Header?
            
            let didParse = framer.parseInput(minimumIncompleteLength: headerSize, maximumLength: headerSize) { buffer, isComplete -> Int in
                guard let buffer = buffer, buffer.count >= headerSize else {
                    return 0
                }
                
                header = buffer.bindMemory(to: Header.self)[0]
                
                // Advance the cursor the size of the header.
                return headerSize
            }
            
            guard didParse, let messageLength = header else {
                return headerSize
            }
            
            let message = NWProtocolFramer.Message(definition: LengthPrefixedFramer.definition)
            if !framer.deliverInputNoCopy(length: Int(messageLength), message: message, isComplete: true) {
                return 0
            }
        }
    }
    
    public func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        do {
            var header = UInt32(messageLength)
            let headerData = withUnsafeBytes(of: &header) { buffer -> Data in
                Data(buffer: buffer.bindMemory(to: UInt8.self))
            }
            
            framer.writeOutput(data: headerData)
            try framer.writeOutputNoCopy(length: messageLength)
        } catch let error {
            self.logger.log("Error while writing output: \(error)")
        }
    }
    
    public func wakeup(framer: NWProtocolFramer.Instance) {}
    
    public func stop(framer: NWProtocolFramer.Instance) -> Bool {
        true
    }
    
    public func cleanup(framer: NWProtocolFramer.Instance) {}
}
