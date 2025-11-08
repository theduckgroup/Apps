import Foundation

public var debugging: Bool {
    false
}

public var isRunningForPreviews: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
