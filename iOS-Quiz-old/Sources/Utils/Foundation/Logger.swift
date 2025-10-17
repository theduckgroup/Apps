import Foundation
import os

private let osLogger = os.Logger()

struct Logger {
    let osLoggerLimit = 32_000
    
    init() {}
    
    func info(_ message: String) {
        if isRunningForPreviews {
            print("INFO: \(message)")
            return
        }
        
        osLog(.info, message: message)
    }
    
    func error(_ message: String) {
        if isRunningForPreviews {
            print("ERROR: \(message)")
            return
        }
        
        osLog(.error, message: "ERROR: \(message)")
    }
    
    private func osLog(_ level: OSLogType, message: String) {
        if message.utf8.count < osLoggerLimit {
            osLogger.log(level: level, "\(message, privacy: .public)")
            
        } else {
            let formattedDate = Date().formatted(
                .dateTime.hour(.twoDigits(amPM: .abbreviated))
                .minute(.twoDigits)
                .second(.twoDigits)
                .secondFraction(.fractional(3))
            )
            
            let formattedLevel = switch level {
            case .info: "INFO"
            case .error: "ERROR"
            default: fatalError()
            }
            
            let formattedMessage =
                """
                [Message] [\(formattedDate)] [\(formattedLevel)]
                \(message)
                [End Message]
                """
            
            print(formattedMessage)
        }
    }
}

let logger = Logger()

