import Foundation

struct Stock: Decodable {
    var storeId: String
    var itemAttributes: [ItemAttributes]
}

extension Stock {
    struct ItemAttributes: Decodable {
        var itemId: String
        var quantity: Int
    }
}
