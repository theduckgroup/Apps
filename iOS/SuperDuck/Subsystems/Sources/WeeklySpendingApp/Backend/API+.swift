import Foundation
import Common
import Backend

extension API {
    func template() async throws -> WSTemplate {
        try await get(path: "ws-app/templates/6905482c7eb3588dc38a48c8")
    }
    
    func mockTemplate() async throws -> WSTemplate {
        try await get(authenticated: false, path: "ws-app/mock-template")
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
