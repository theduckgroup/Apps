import Foundation
import Backend
import Common

extension API {
    func store() async throws -> Store {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/store")
        }

        return try await get(path: "inventory-app/store/\(Store.defaultStoreID)")
    }
    
    func stock() async throws -> Stock {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/store/stock")
        }

        return try await get(path: "inventory-app/store/\(Store.defaultStoreID)/stock")
    }
    
    func stockChangesMeta(storeId: String, userId: String) async throws -> [StockChangeMeta] {
        if isRunningForPreviews {
            return [.mock1, .mock2, .mock3]
        }
        
        return try await get(path: "inventory-app/store/\(storeId)/stock/changes/meta/by-user/\(userId)")
    }
    
    func stockChange(storeId: String, changeId: String) async throws -> StockChange {
        if isRunningForPreviews {
            return .mock
        }
        
        return try await get(path: "inventory-app/store/\(storeId)/stock/changes/\(changeId)")
    }
}
