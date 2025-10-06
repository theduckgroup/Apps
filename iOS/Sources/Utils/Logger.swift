import Foundation
import os

private let osLogger = os.Logger()

struct Logger {
    init() {}
    
    func info(_ message: String) {
        osLogger.info("\(message, privacy: .public)")
    }
    
    func error(_ message: String) {
        osLogger.error("ERROR: \(message, privacy: .public)")
    }
}

let logger = Logger()

