import Foundation
import Supabase
import Backend

struct WSReport: Codable, Sendable {
    var template: WSTemplate
    var user: User
    var date: Date
    var suppliersData: [SupplierData]
    var customSuppliersData: [CustomSupplierData]
}

extension WSReport {
    struct User: Hashable, Codable, Sendable {
        var id: String
        var email: String
        var name: String
    }
    
    struct SupplierData: Codable, Sendable {
        var supplierId: String
        var amount: Decimal
        var gst: Decimal
        var credit: Decimal
    }
    
    struct CustomSupplierData: Codable, Sendable {
        var name: String
        var amount: Decimal
        var gst: Decimal
        var credit: Decimal
    }
}

extension WSReport.User {
    init(from user: Supabase.User) {
        self.init(id: user.idString, email: user.email ?? "", name: user.name)
    }
}

extension WSReport.User {
    static let mock = Self.init(id: "0", email: "theduckgroupapp@gmail.com", name: "The Duck Group App")
}
