//import Foundation
//import Combine
//
//@Observable @MainActor
//class InventoryStore {
//    static let shared = {
//        if isRunningForPreviews {
//            return InventoryStore(forPreview: ())
//        }
//        
//        return InventoryStore()
//    }()
//    
//    private(set) var metavendors: [Metavendor] = []
//    private(set) var vendorsMap: [String: Vendor] = [:]
//    private var selectedVendorEventsCancellable: Cancellable?
//    
//    var selectedVendorId: String? {
//        didSet {
//            guard selectedVendorId != oldValue else {
//                return
//            }
//            
//            if let selectedVendorId {
//                let publisher = EventHub.shared.vendorChanged(vendorId: selectedVendorId)
//
//                selectedVendorEventsCancellable = publisher.sink {
//                    Task {
//                        try await self.fetchVendor(self.selectedVendorId!)
//                    }
//                }
//                
//            } else {
//                selectedVendorEventsCancellable?.cancel()
//            }
//        }
//    }
//        
//    
//    init() {}
//    
//    init(forPreview: Void) {
//        self.metavendors = [
//            .init(id: "0", name: "ND Central Kitchen")
//        ]
//        
//        let vendor = Vendor(
//            id: "0",
//            name: "ND Central Kitchen",
//            items: [
//                .init(id: "01", name: "Yoghurt Cube - 6 pcs", code: "BD001", quantity: 100),
//                .init(id: "02", name: "Pink Cube - 6 pcs", code: "BD002", quantity: 50),
//                .init(id: "03", name: "Yellow Cube - 6 pcs", code: "BD003", quantity: 30),
//                .init(id: "04", name: "Green Cube - 6 pcs", code: "BD004", quantity: 80),
//                
//                .init(id: "11", name: "Coconut Fine - 500g", code: "BDD001", quantity: 2),
//                .init(id: "12", name: "Organic Black Chia Seeds - 500g", code: "BDD002", quantity: 9),
//            ],
//            sections: [
//                .init(id: "1", name: "Blended Drinks - Frozen Smoothies Cubes", rows: [
//                    .init(itemId: "01"),
//                    .init(itemId: "02"),
//                    .init(itemId: "03"),
//                    .init(itemId: "04"),
//                ]),
//                .init(id: "2", name: "Blended Drinks - Decorations", rows: [
//                    .init(itemId: "11"),
//                    .init(itemId: "12")
//                ])
//            ]
//        )
//        
//        self.vendorsMap = [
//            "0": vendor
//        ]
//        
//        self.selectedVendorId = "0"
//    }
//    
//    var selectedVendor: Vendor? {
//        selectedVendorId.flatMap { vendorsMap[$0] }
//    }
//    
//    func fetchMetavendors() async throws {
//        let request = try await InventoryServer.makeRequest(httpMethod: "GET", path: "/api/vendors")
//        metavendors = try await HTTPClient.shared.get(request, decodeAs: [Metavendor].self)
//    }
//    
//    func fetchVendor(_ vendorId: String) async throws {
//        var request = try await InventoryServer.makeRequest(httpMethod: "GET", path: "/api/vendor/\(vendorId)")
//        request.url!.append(queryItems: [.init(name: "withQuantity", value: "1")])
//        
//        let vendor = try await HTTPClient.shared.get(request, decodeAs: Vendor.self)
//        
//        vendorsMap[vendor.id] = vendor
//    }
//    
//    func submit(_ vendor: Vendor, _ scannedItems: [ScannedItem]) async throws {
//        // try await Task.sleep(for: .seconds(1))
//        
//        // Server logic
//        
////        guard let index = vendors.firstIndex(where: { $0.id == vendor.id }) else {
////            throw GenericError("Vendor not found")
////        }
////        
////        for scannedItem in scannedItems {
////            guard let itemIndex = vendors[index].itemQuantityData.firstIndex(where: { $0.itemID == scannedItem.itemID }) else {
////                continue
////            }
////            
////            vendors[index].itemQuantityData[itemIndex].quantity += 1
////        }
////        
//        
//        // refresh()
//    }
//    
//    /// Retrieves data from server.
//    func refresh() {
//        
//    }
//}
