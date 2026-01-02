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
    
    func storeStock() async throws -> StoreStock {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/store/stock")
        }

        return try await get(path: "inventory-app/store/\(Store.defaultStoreID)/stock")
    }
}
