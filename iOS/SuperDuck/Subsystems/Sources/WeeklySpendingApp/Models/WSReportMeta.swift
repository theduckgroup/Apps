import Foundation
import Supabase
import Backend

struct WSReportMeta: Hashable, Decodable, Sendable {
    var id: String
    var template: WSTemplateMeta
    var user: WSReport.User
    var date: Date
}


struct WSTemplateMeta: Hashable, Decodable {
    var id: String
    var name: String
    var code: String
}


extension WSReportMeta {
    static let mock1 = WSReportMeta(id: "1", template: .mock, user: .mock, date: Date())
    static let mock2 = WSReportMeta(id: "2", template: .mock, user: .mock, date: Date().addingTimeInterval(-24 * 60 * 60 * 1))
    static let mock3 = WSReportMeta(id: "3", template: .mock, user: .mock, date: Date().addingTimeInterval(-24 * 60 * 60 * 7))
}

extension WSTemplateMeta {
    static let mock = Self.init(id: "1", name: "Weekly Spending", code: "WEEKLY_SPENDING")
}
