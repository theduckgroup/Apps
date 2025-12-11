import Foundation

nonisolated struct Template: Decodable, Identifiable, Sendable {
    var id: String
    var name: String
    var emailRecipients: [String]
    var suppliers: Supplier
    var sections: [Section]
}

extension Template {
    struct Supplier: Decodable, Sendable {
        var id: String
        var name: String
        var gstMethod: GSTMethod

    }
    
    enum GSTMethod: String, Decodable, Sendable {
        case notApplicable
        case tenPercent = "10%"
        case input
    }
    
    struct Section: Decodable, Sendable {
        var id: String
        var name: String
        var rows: [Row]
    }
    
    struct Row: Decodable, Sendable {
        var supplierId: String
    }
}
