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
        var offset: OffsetChange?
        var set: SetChange?
        
        struct OffsetChange: Decodable {
            var delta: Int
            var oldValue: Int
            var newValue: Int
        }
        
        struct SetChange: Decodable {
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
        
        var oldQuantity: Int {
            offset?.oldValue ?? set?.oldValue ?? 0
        }
        
        var newQuantity: Int {
            offset?.newValue ?? set?.newValue ?? 0
        }
    }
}

extension StockAdjustment {
    static let mock = StockAdjustment(
        id: "mock-adjustment-1",
        storeId: Store.defaultStoreID,
        timestamp: Date(),
        user: .init(id: "user-1", email: "user@example.com"),
        changes: [
            .init(itemId: "item-1", offset: .init(delta: 5, oldValue: 10, newValue: 15), set: nil),
            .init(itemId: "item-2", offset: .init(delta: -3, oldValue: 20, newValue: 17), set: nil)
        ]
    )
}
