import Foundation
import Common

extension API.Env {
    static let prod = API.Env(url: URL(string: "https://apps.theduckgroup.com.au/api")!)
    
    static let dev = API.Env(url: URL(string: "https://apps-dev.theduckgroup.com.au/api")!)
    
    static let local = API.Env(
        url: {
            let localIPFileURL = Bundle.main.url(forResource: "LocalIP", withExtension: nil)!
            let localIP = try! String(contentsOf: localIPFileURL, encoding: .utf8).trimmed()
            return  URL(string: "http://\(localIP):8021/api")!
        }()
    )
}
