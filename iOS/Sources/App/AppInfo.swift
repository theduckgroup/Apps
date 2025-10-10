import Foundation

struct AppInfo {
    static var bundleVersion: String {
        Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
}

enum Target {
    case prod
    case local
}

extension Target {
    static var current: Target {
        switch Bundle.main.bundleIdentifier! {
        case "au.com.theduckgroup.Quiz": .prod
        case "au.com.theduckgroup.Quiz-local": .local
        default: fatalError("Unknown bundle identifier")
        }
    }
}
