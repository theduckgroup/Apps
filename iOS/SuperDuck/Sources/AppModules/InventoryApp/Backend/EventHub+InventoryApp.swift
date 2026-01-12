import Foundation

extension EventHub {
    var storeChangeEvents: AsyncStream<Void> {
        events("inventory-app:store:\(Store.defaultStoreID):changed")
    }

}
