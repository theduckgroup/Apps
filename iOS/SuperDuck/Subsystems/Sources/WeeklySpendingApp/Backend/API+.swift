import Foundation
import Common
import Backend

extension API {
    func template(code: String) async throws -> WSTemplate {
        let templates: [WSTemplate] = try await get(
            path: "ws-app/templates",
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
        try await get(path: "ws-app/reports/\(id)")
    }
    
    func userReports(userID: String) async throws -> [WSReportMeta] {
        try await get(path: "ws-app/users/\(userID)/reports/meta")
    }
    
    func submitReport(_ report: WSReport) async throws {
        try await post(method: "POST", path: "ws-app/reports/submit", body: report)
    }

    func mockReport() async throws -> WSReport {
        try await get(authenticated: false, path: "ws-app/mock-report")
    }
}
