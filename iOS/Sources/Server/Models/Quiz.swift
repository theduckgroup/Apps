import Foundation

struct Quiz: Identifiable, Decodable {
    var id: String
    var name: String
    var code: String
    var itemsPerPage: Int
    var items: [Item]
    var sections: [Section]
    
    func itemForID(_ id: String) -> Item? {
        let item = items.first { $0.id == id }
        assert(item != nil)
        return item
    }
    
    func itemsForSection(_ section: Section) -> [Item] {
        section.rows.compactMap { row in
            let item = items.first { $0.id == row.itemId }
            assert(item != nil)
            
            return item
        }
    }
}

extension Quiz {
    enum Item: Identifiable, Decodable {
        case selectedResponseItem(SelectedResponseItem)
        case textInputItem(TextInputItem)
        case listItem(ListItem)
        
        var id: String {
            switch self {
            case .selectedResponseItem(let item): item.id
            case .textInputItem(let item): item.id
            case .listItem(let item): item.id
            }
        }
        
        var kind: ItemKind {
            switch self {
            case .selectedResponseItem(_): .selectedResponseItem
            case .textInputItem(_): .textInputItem
            case .listItem(_): .listItem
            }
        }
        
        // Type casting
        
        func `as`<T>(_ type: T.Type) -> T {
            if T.self == SelectedResponseItem.self {
                guard case .selectedResponseItem(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            if T.self == TextInputItem.self {
                guard case .textInputItem(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            if T.self == ListItem.self {
                guard case .listItem(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            preconditionFailure()
        }
        
        // Decode
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(ItemKind.self, forKey: .kind)
            
            switch kind {
            case .selectedResponseItem:
                let item = try SelectedResponseItem(from: decoder)
                self = .selectedResponseItem(item)
                
            case .textInputItem:
                let item = try TextInputItem(from: decoder)
                self = .textInputItem(item)
                
            case .listItem:
                let item = try ListItem(from: decoder)
                self = .listItem(item)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case kind
        }
    }
    
//    struct Item: Decodable {
//        var id: String
//        var kind: String
//        var data: ItemData
//        
//        enum Kind {
//            case selectedResponseItem
//            case textInputItem
//            case listItem
//        }
//    }
    
    struct SelectedResponseItem: Decodable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Decodable {
            var prompt: String
            var options: [Option]
            
            struct Option: Identifiable, Decodable {
                var id: String
                var value: String
            }
        }
    }
    
    struct TextInputItem: Decodable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Decodable {
            var prompt: String
        }
    }
    
    struct ListItem: Decodable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Decodable {
            var prompt: String
            var items: [Item]
        }
    }
    
    enum ItemKind: Decodable {
        case selectedResponseItem
        case textInputItem
        case listItem
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

extension Quiz {
    static let mock = Quiz(
        id: "mock",
        name: "FOH Kitchen Staff Knowledge",
        code: "FOH_KITCHEN_STAFF",
        itemsPerPage: 10,
        items: [],
        sections: []
    )
}
