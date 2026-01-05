import Foundation
import Backend
import Common

extension API {
    func store() async throws -> Store {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/_any")
        }

        return try await get(path: "inventory-app/store/\(Store.defaultStoreID)")
    }
    
    func stock() async throws -> Stock {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/_any/stock")
        }

        return try await get(path: "inventory-app/store/\(Store.defaultStoreID)/stock")
    }
    
    func stockChangesMeta(storeId: String, userId: String) async throws -> [StockChangeMeta] {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/_any/stock/changes/meta")
        }
        
        return try await get(path: "inventory-app/store/\(storeId)/stock/changes/meta/by-user/\(userId)")
    }
    
    func stockChange(storeId: String, changeId: String) async throws -> StockChange {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/stores/\(storeId)/stock/changes/_any")
        }
        
        return try await get(path: "inventory-app/store/\(storeId)/stock/changes/\(changeId)")
    }
}
