import Foundation

struct AppInfo {
    static var buildTarget: BuildTarget {
        switch Bundle.main.bundleIdentifier! {
        case "au.com.theduckgroup.SuperDuck": .prod
        case "au.com.theduckgroup.SuperDuck-local": .local
        default: fatalError("Unknown bundle identifier")
        }
    }
    
    static var marketingVersion: String {
        Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    static var bundleVersion: String {
        Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
}

extension AppInfo {
    enum BuildTarget {
        case prod
        case local
    }
}
