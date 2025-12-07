import Foundation

/// Whether the app is running in debugging.
///
/// Returns `true` if one of these is true:
/// - `DEBUG` flag is true
/// - Running in simulator
/// - Debugger is attached
///
/// Computed once when first accessed and is cached.
public let debugging: Bool = {
#if DEBUG || targetEnvironment(simulator)
    true
#else
    // Whether debugger is attached (ie running from Xcode)
    // This works with Release builds
    getppid() != 1
#endif
}()

public var isRunningForPreviews: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}
