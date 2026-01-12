import Foundation
import Common

struct ScanRecord {
    let storeItem: Store.Item
    let quantity: Int
}

struct ScanRecordGroup {
    let storeItem: Store.Item
    let totalQuantity: Int
}

extension Sequence<ScanRecord> {
    func grouped() -> [ScanRecordGroup] {
        Dictionary(grouping: self, by: \.storeItem.id)
            .map { key, records in
                let totalQuantity = records.reduce(0) { $0 + $1.quantity }
                return ScanRecordGroup(storeItem: records[0].storeItem, totalQuantity: totalQuantity)
            }
            .localizedStandardSorted(on: \.storeItem.name)
    }
}
