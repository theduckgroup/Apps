import Foundation
import Backend
import Common

extension API {
    func store() async throws -> Vendor {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/store")
        }
        
        return try await get(path: "inventory-app/store/\(Vendor.defaultStoreID)")
    }
    
    func storeStock() async throws -> StoreStock {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "inventory-app/mock/store/stock")
        }
        
        return try await get(path: "inventory-app/store/\(Vendor.defaultStoreID)/stock")
    }
    
    func submit(_ vendor: Vendor, _ scannedItems: [ScannedItem]) async throws {
        // try await Task.sleep(for: .seconds(1))
        
        // Server logic
        
        //        guard let index = vendors.firstIndex(where: { $0.id == vendor.id }) else {
        //            throw GenericError("Vendor not found")
        //        }
        //
        //        for scannedItem in scannedItems {
        //            guard let itemIndex = vendors[index].itemQuantityData.firstIndex(where: { $0.itemID == scannedItem.itemID }) else {
        //                continue
        //            }
        //
        //            vendors[index].itemQuantityData[itemIndex].quantity += 1
        //        }
        //
        
        // refresh()
    }

}

//class InventoryServer {
//    static var url: URL {
//        switch Target.current {
//        case .prod: fatalError()
//        case .local: URL(string: "http://192.168.0.207:7021")!
//        }
//    }
//    
//    static func makeRequest(httpMethod: String, path: String) async throws -> URLRequest {
//        var request = URLRequest(url: url.appending(path: path))
//        request.httpMethod = httpMethod
//        
//        let tokens = try await DuckAuth.shared.tokens()
//        
//        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("mobile", forHTTPHeaderField: "Client-Type")
//       
//        return request
//    }
//}
