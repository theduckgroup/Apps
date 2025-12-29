import Foundation

/// A vendor.
struct Vendor: Decodable {
    var id: String
    var name: String
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

extension Vendor {
    static let defaultStoreID = "69509ae69da8c740e58d83c1"
}

extension Vendor {
    struct Item: Decodable {
        var id: String
        var name: String
        var code: String
        var quantity: Int
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

extension Vendor {
    static let mock = Vendor(
        id: "nd-central-kitchen",
        name: "ND Central Kitchen",
        items: [],
        sections: []
    )
}
