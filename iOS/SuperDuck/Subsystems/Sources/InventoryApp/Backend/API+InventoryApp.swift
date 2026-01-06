import Foundation
import Backend
import Common

extension API {
    func store() async throws -> Store {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/_any")
        }

        return try await get(path: "/inventory-app/stores/\(Store.defaultStoreID)")
    }
    
    func stock() async throws -> Stock {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/_any/stock")
        }

        return try await get(path: "/inventory-app/stores/\(Store.defaultStoreID)/stock")
    }
    
    func stockAdjustmentsMeta(storeId: String, userId: String) async throws -> [StockAdjustmentMeta] {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "/inventory-app/mock/stores/_any/stock/adjustments/meta")
        }
        
        return try await get(path: "/inventory-app/stores/\(storeId)/stock/adjustments/meta/by-user/\(userId)")
    }
    
    func stockAdjustment(storeId: String, adjustmentId: String) async throws -> StockAdjustment {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "/inventory-app/mock/stores/\(storeId)/stock/adjustments/_any")
        }
        
        return try await get(path: "/inventory-app/stores/\(storeId)/stock/adjustments/\(adjustmentId)")
    }
}
