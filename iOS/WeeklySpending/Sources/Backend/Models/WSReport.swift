import Foundation
import Supabase
import Backend

struct WSReport: Encodable, Sendable {
    var template: WSTemplate
    var user: User
    var date: Date
    var suppliersData: [SupplierData]
    var customSuppliersData: [CustomSupplierData]
}

extension WSReport {
    struct User: Encodable, Sendable {
        var id: String
        var email: String
        var name: String
    }
    
    struct SupplierData: Encodable, Sendable {
        var supplierId: String
        var amount: Decimal
        var gst: Decimal
    }
    
    struct CustomSupplierData: Encodable, Sendable {
        var name: String
        var amount: Decimal
        var gst: Decimal
    }
}


extension WSReport.User {
    init(from user: Supabase.User) {
        self.init(id: user.id.uuidString, email: user.email ?? "", name: user.name)
    }
}
