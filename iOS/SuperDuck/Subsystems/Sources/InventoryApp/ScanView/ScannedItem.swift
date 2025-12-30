import Foundation

struct ScannedItem {
    let itemID: String
    let code: String
    let name: String
}

struct ScannedItemGroup {
    let item: ScannedItem
    let count: Int
}

extension Sequence<ScannedItem> {
    func grouped() -> [ScannedItemGroup] {
        Dictionary(grouping: self, by: \.itemID )
            .map { key, items in
                .init(item: items[0], count: items.count)
            }
            .localizedStandardSorted(on: \.item.name)
    }
}
