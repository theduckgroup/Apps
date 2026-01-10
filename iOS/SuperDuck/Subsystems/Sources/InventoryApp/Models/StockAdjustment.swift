import Foundation

struct StockAdjustment: Decodable, Identifiable {
    var id: String
    var storeId: String
    var timestamp: Date
    var user: User
    var changes: [Change]
    
    struct User: Decodable {
        var id: String
        var email: String
    }
    
    struct Change: Decodable {
        var itemId: String
        var offset: Offset?
        var set: Set?
        
        struct Offset: Decodable {
            var delta: Int
            var oldValue: Int
            var newValue: Int
        }
        
        struct Set: Decodable {
            var oldValue: Int
            var newValue: Int
        }
        
        // Computed property for backward compatibility
        var delta: Int {
            if let offset = offset {
                return offset.delta
            } else if let set = set {
                return set.newValue - set.oldValue
            }
            return 0
        }
    }
}
