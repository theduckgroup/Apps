import Foundation

// TODO: Remove @MainActor
@MainActor
public extension API {
    static let prod = API(
        url: URL(string: "https://apps.theduckgroup.com.au/api")!,
        auth: .shared
    )
    
    static let localhost = API(
        url: URL(string: "http://localhost:8021/api")!,
        auth: .shared
    )
}
