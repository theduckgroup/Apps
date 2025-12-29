import Foundation

public struct AppInfo {
    public static var buildTarget: BuildTarget {
        switch Bundle.main.bundleIdentifier! {
        case "au.com.theduckgroup.SuperDuck": .prod
        case "au.com.theduckgroup.SuperDuck-local": .local
        case "previews.com.apple.PreviewAgent.iOS": .local // Happens in packages
        default: fatalError("Unknown bundle identifier")
        }
    }
    
    public static var marketingVersion: String {
        Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    public static var bundleVersion: String {
        Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
}

public extension AppInfo {
    enum BuildTarget {
        case prod
        case local
    }
}
