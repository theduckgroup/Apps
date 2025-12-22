import Foundation

public extension API.Env {
    static let prod = API.Env(
        url: URL(string: "https://apps.theduckgroup.com.au/api")!
    )
    
    static let local = API.Env(
        url: {
            let localIPFileURL = Bundle.module.url(forResource: "LocalIP", withExtension: nil)!
            let localIP = try! String(contentsOf: localIPFileURL, encoding: .utf8).trimmed()
            return  URL(string: "http://\(localIP):8021/api")!
        }()
    )
}
