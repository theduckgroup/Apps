import Foundation

struct WSTemplate: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var code: String
    var emailRecipients: [String]
    var suppliers: [Supplier]
    var sections: [Section]
}

extension WSTemplate {
    struct Supplier: Codable, Sendable {
        var id: String
        var name: String
        var gstMethod: GSTMethod
    }
    
    enum GSTMethod: String, Codable, Sendable {
        case notApplicable
        case tenPercent = "10%"
        case input
    }
    
    struct Section: Codable, Sendable {
        var id: String
        var name: String
        var rows: [Row]
    }
    
    struct Row: Codable, Sendable {
        var supplierId: String
    }
}
