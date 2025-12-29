import Backend

extension EventHub {
    var templatesChangeEvents: AsyncStream<Void> {
        events("inventory-app:store:\(Vendor.defaultStoreID):changed")
    }
    
}
