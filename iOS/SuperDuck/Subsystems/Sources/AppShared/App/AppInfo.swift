//import Foundation
//
//public struct AppInfo {
//    public static var buildTarget: BuildTarget {
//        switch Bundle.main.bundleIdentifier! {
//        case "au.com.theduckgroup.SuperDuck": return .prod
//        case "au.com.theduckgroup.SuperDuck-local": return .local
//        default: fatalError("Unknown bundle identifier")
//        }
//    }
//    
//    public static var marketingVersion: String {
//        Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
//    }
//    
//    public static var bundleVersion: String {
//        Bundle.main.infoDictionary!["CFBundleVersion"] as! String
//    }
//}
//
//extension AppInfo {
//    public enum BuildTarget {
//        case prod
//        case local
//    }
//}
