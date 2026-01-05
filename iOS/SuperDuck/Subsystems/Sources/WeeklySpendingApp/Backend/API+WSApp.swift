import Foundation
import Common
import Backend

extension API {
    func template() async throws -> WSTemplate {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/template")
        }

        return try await get(path: "ws-app/templates/6905482c7eb3588dc38a48c8")
    }
    
    func report(id: String) async throws -> WSReport {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/report")
        }
        
        return try await get(path: "ws-app/reports/\(id)")
    }
    
    func userReportMetas(userID: String) async throws -> [WSReportMeta] {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/users/_any/reports/meta")
        }
     
        return try await get(path: "ws-app/users/\(userID)/reports/meta")
    }
    
    func submitReport(_ report: WSReport) async throws {
        try await post(method: "POST", path: "ws-app/reports/submit", body: report)
    }
}
