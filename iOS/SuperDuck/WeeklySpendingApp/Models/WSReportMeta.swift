import Foundation
import Supabase

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
