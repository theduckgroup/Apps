import Foundation

struct StockChangeMeta: Hashable, Decodable, Identifiable {
    var id: String
    var storeId: String
    var timestamp: Date
    var totalQuantityChange: Int
}

extension StockChangeMeta {
    static let mock1 = StockChangeMeta(
        id: "mock-change-1",
        storeId: Store.defaultStoreID,
        timestamp: Date(),
        totalQuantityChange: 5
    )
    
    static let mock2 = StockChangeMeta(
        id: "mock-change-2",
        storeId: Store.defaultStoreID,
        timestamp: Date().addingTimeInterval(-3600),
        totalQuantityChange: -10
    )
    
    static let mock3 = StockChangeMeta(
        id: "mock-change-3",
        storeId: Store.defaultStoreID,
        timestamp: Date().addingTimeInterval(-7200),
        totalQuantityChange: 15
    )
}
