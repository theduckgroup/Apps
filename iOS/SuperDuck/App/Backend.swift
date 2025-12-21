import Foundation
import Backend
import Common

extension API {
    static let shared: API = {
        if isRunningForPreviews {
            return .localhost
        }
        
        switch AppInfo.buildTarget {
        case .prod:
            return .prod
            
        case .local:
            let localIPFileURL = Bundle.main.url(forResource: "LocalIP", withExtension: nil)!
            let localIP = try! String(contentsOf: localIPFileURL, encoding: .utf8).trimmed()
            
            return API(
                url: URL(string: "http://\(localIP):8021/api")!,
                auth: .shared
            )
        }
    }()
}

extension Auth {
    // static let auth = Auth()
}
