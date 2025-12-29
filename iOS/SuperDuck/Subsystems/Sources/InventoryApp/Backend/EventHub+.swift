import Backend

extension EventHub {
    var storeChangeEvents: AsyncStream<Void> {
        events("inventory-app:store:\(Vendor.defaultStoreID):changed")
    }
    
}
