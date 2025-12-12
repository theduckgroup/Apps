import Foundation
import Common
import Backend

/// Server API.
extension API {
    static let shared = API(
        auth: .shared,
        baseURL: {
            switch AppInfo.buildTarget {
            case .prod: URL(string: "https://apps.theduckgroup.com.au/api/ws-app")!
            case .local: URL(string: "http://192.168.0.207:8021/api/ws-app")!
            }
        }()
    )
}

extension API {
    func template(code: String) async throws -> WSTemplate {
        try await get(
            path: "/template",
            queryItems: [.init(name: "code", value: code)],
            decodeAs: WSTemplate.self
        )
    }
    
    func mockTemplate() async throws -> WSTemplate {
        try await get(authenticated: false, path: "/mock-template", decodeAs: WSTemplate.self)
    }
    
    func submitReport(_ report: WSReport) async throws {
        try await post(method: "POST", path: "/report/submit", body: report)
    }
}
