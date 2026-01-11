import Foundation

struct Store: Decodable {
    var id: String
    var name: String
    var catalog: Catalog
}

extension Store {
    static let defaultStoreID = "69509ae69da8c740e58d83c1"
}

extension Store {
    struct Catalog: Decodable {
        var items: [Item]
        var sections: [Section]

        func itemsForSection(_ section: Section) -> [Item] {
            section.rows.compactMap { row in
                let item = items.first { $0.id == row.itemId }
                assert(item != nil)

                return item
            }
        }
    }

    struct Item: Decodable {
        var id: String
        var name: String
        var code: String
        // var quantity: Int
    }

    struct Section: Decodable {
        var id: String
        var name: String
        var rows: [Row]

        struct Row: Decodable {
            var itemId: String
        }
    }
}

extension Store {
    static let mock = Store(
        id: "nd-central-kitchen",
        name: "ND Central Kitchen",
        catalog: .init(items: [], sections: [])
    )
}
