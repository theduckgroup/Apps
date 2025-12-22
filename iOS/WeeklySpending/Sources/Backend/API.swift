import Foundation
import Common
import Backend_deprecated

/// Server API.
extension API {
    static let shared = API(
        auth: .shared,
        baseURL: {
            switch AppInfo.buildTarget {
            case .prod: URL(string: "https://apps.theduckgroup.com.au/api/ws-app")!
            case .local: URL(string: "http://192.168.1.163:8021/api/ws-app")!
            }
        }()
    )
}

extension API {
    func template(code: String) async throws -> WSTemplate {
        let templates: [WSTemplate] = try await get(
            path: "/templates",
            queryItems: [.init(name: "code", value: code)]
        )
        
        switch templates.count {
        case 0:
            throw GenericError("No template with code WEEKLY_SPENDING found")
            
        case 1:
            return templates[0]
            
        default:
            throw GenericError("More than one template with code WEEKLY_SPENDING found")
        }
    }
    
    func mockTemplate() async throws -> WSTemplate {
        try await get(authenticated: false, path: "/mock-template")
    }
    
    
    func report(id: String) async throws -> WSReport {
        try await get(path: "/reports/\(id)")
    }
    
    func userReports(userID: String) async throws -> [WSReportMeta] {
        try await get(path: "/users/\(userID)/reports/meta")
    }
    
    func mockReport() async throws -> WSReport {
        try await get(authenticated: false, path: "/mock-report")
    }    
    
    func submitReport(_ report: WSReport) async throws {
        try await post(method: "POST", path: "/reports/submit", body: report)
    }
}
