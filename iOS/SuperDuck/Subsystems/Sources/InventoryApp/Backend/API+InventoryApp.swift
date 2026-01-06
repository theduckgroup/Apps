import Foundation
import Backend
import Common

struct StockAdjustmentsMetaResponse: Decodable {
    var adjustments: [StockAdjustmentMeta]
    var since: Date
}

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
    
    func stockAdjustmentsMeta(storeId: String, userId: String) async throws -> StockAdjustmentsMetaResponse {
        if isRunningForPreviews {
            let adjustments: [StockAdjustmentMeta] = try await get(authenticated: false, path: "/inventory-app/mock/stores/_any/stock/adjustments/meta")
            let calendar = Calendar.current
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            return StockAdjustmentsMetaResponse(adjustments: adjustments, since: sixMonthsAgo)
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
