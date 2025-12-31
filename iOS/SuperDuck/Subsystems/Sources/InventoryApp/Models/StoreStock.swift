import Foundation

struct StoreStock: Decodable {
    var storeId: String
    var itemAttributes: [ItemAttributes]
}

extension StoreStock {
    struct ItemAttributes: Decodable {
        var itemId: String
        var quantity: Int
    }
}
