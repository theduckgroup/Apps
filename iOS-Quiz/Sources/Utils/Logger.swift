import Foundation
import os

private let osLogger = os.Logger()

struct Logger {
    init() {}
    
    func info(_ message: String) {
        if isRunningForPreviews {
            print("INFO: \(message)")
            return
        }
        
        osLogger.info("\(message, privacy: .public)")
    }
    
    func error(_ message: String) {
        if isRunningForPreviews {
            print("ERROR: \(message)")
            return
        }
        
        osLogger.error("ERROR: \(message, privacy: .public)")
    }
}

let logger = Logger()

