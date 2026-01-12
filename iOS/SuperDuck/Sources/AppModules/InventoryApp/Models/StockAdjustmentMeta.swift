import Foundation

struct StockAdjustmentMeta: Hashable, Decodable, Identifiable {
    var id: String
    var storeId: String
    var timestamp: Date
    var totalQuantityChange: Int
}

extension StockAdjustmentMeta {
    static let mock1 = StockAdjustmentMeta(
        id: "mock-adjustment-1",
        storeId: Store.defaultStoreID,
        timestamp: Date(),
        totalQuantityChange: 5
    )
    
    static let mock2 = StockAdjustmentMeta(
        id: "mock-adjustment-2",
        storeId: Store.defaultStoreID,
        timestamp: Date().addingTimeInterval(-3600),
        totalQuantityChange: -10
    )
    
    static let mock3 = StockAdjustmentMeta(
        id: "mock-adjustment-3",
        storeId: Store.defaultStoreID,
        timestamp: Date().addingTimeInterval(-7200),
        totalQuantityChange: 15
    )
}
