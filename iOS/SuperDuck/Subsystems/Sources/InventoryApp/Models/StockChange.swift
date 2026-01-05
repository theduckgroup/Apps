import Foundation

struct StockChange: Decodable, Identifiable {
    var id: String
    var storeId: String
    var timestamp: Date
    var user: User
    var itemQuantityChanges: [ItemQuantityChange]
    
    struct User: Decodable {
        var id: String
        var email: String
    }
    
    struct ItemQuantityChange: Decodable, Identifiable {
        var itemId: String
        var delta: Int
        var oldQuantity: Int
        var newQuantity: Int
        
        var id: String { itemId }
    }
}

extension StockChange {
    static let mock = StockChange(
        id: "mock-change-1",
        storeId: Store.defaultStoreID,
        timestamp: Date(),
        user: .init(id: "user-1", email: "user@example.com"),
        itemQuantityChanges: [
            .init(itemId: "item-1", delta: 5, oldQuantity: 10, newQuantity: 15),
            .init(itemId: "item-2", delta: -3, oldQuantity: 20, newQuantity: 17)
        ]
    )
}
