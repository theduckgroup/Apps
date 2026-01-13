import Foundation
import Common

extension API {
    func template() async throws -> WSTemplate {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/templates/_any")
        }

        return try await get(path: "ws-app/templates/6905482c7eb3588dc38a48c8")
    }

    func report(id: String) async throws -> WSReport {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/reports/_any")
        }

        return try await get(path: "ws-app/reports/\(id)")
    }

    func userReportMetas(userID: String) async throws -> WSReportsMetaResponse {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "ws-app/mock/users/_any/reports/meta")
        }

        return try await get(path: "ws-app/users/\(userID)/reports/meta")
    }

    func submitReport(_ report: WSReport) async throws {
        try await post(method: "POST", path: "ws-app/reports/submit", body: report)
    }
}

extension API {
    struct WSReportsMetaResponse: Decodable {
        var data: [WSReportMeta]
        var since: Date
    }
}
