import Foundation

struct Quiz: Identifiable {
    var id: String
    var name: String
    var code: String
    var itemsPerPage: Int
    var items: [any Item]
    var sections: [Section]
    
    func itemForID(_ id: String) -> (any Item)? {
        let item = items.first { $0.id == id }
        assert(item != nil)
        return item
    }
    
    func itemsForSection(_ section: Section) -> [any Item] {
        section.rows.compactMap { row in
            let item = items.first { $0.id == row.itemId }
            assert(item != nil)
            
            return item
        }
    }
}

extension Quiz: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        itemsPerPage = try container.decode(Int.self, forKey: .itemsPerPage)
        items = try container.decode([Quiz.Item].self, forKey: .items)
        sections = try container.decode([Section].self, forKey: .sections)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encode(itemsPerPage, forKey: .itemsPerPage)
        try container.encode(items, forKey: .items)
        try container.encode(sections, forKey: .sections)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case code
        case itemsPerPage
        case items
        case sections
    }
}

extension Quiz {
    protocol Item: Codable {
        var id: String { get }
        var kind: ItemKind { get }
    }
    
    private struct ItemDecodingWrapper: Decodable {
        let item: any Item
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(ItemKind.self, forKey: .kind)
            
            item = switch kind {
            case .selectedResponseItem: try SelectedResponseItem(from: decoder)
            case .textInputItem: try TextInputItem(from: decoder)
            case .listItem: try ListItem(from: decoder)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case kind
        }
    }
    
    struct SelectedResponseItem: Item, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Codable {
            var prompt: String
            var options: [Option]
            
            struct Option: Identifiable, Codable {
                var id: String
                var value: String
            }
        }
    }
    
    struct TextInputItem: Item, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Codable {
            var prompt: String
        }
    }
    
    struct ListItem: Item, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Codable {
            var prompt: String
            var items: [any Item]
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                prompt = try container.decode(String.self, forKey: .prompt)
                items = try container.decode([Quiz.Item].self, forKey: .items)
            }
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(prompt, forKey: .prompt)
                try container.encode(items, forKey: .items)
            }
            
            enum CodingKeys: CodingKey {
                case prompt
                case items
            }
        }
    }
    
    enum ItemKind: String, Codable {
        case selectedResponseItem
        case textInputItem
        case listItem
    }
    
    struct Section: Codable {
        var id: String
        var name: String
        var rows: [Row]
        
        struct Row: Codable {
            var itemId: String
        }
    }
}

// Items coding

extension KeyedDecodingContainer {
    func decode(_ type: [Quiz.Item].Type, forKey key: K) throws -> [Quiz.Item] {
        var nestedContainer = try nestedUnkeyedContainer(forKey: key)
        var items: [Quiz.Item] = []
        
        while !nestedContainer.isAtEnd {
            let itemDecoder = try nestedContainer.superDecoder()
            let kindContainer = try itemDecoder.container(keyedBy: ItemCodingKeys.self)
            let kind = try kindContainer.decode(Quiz.ItemKind.self, forKey: .kind)
            
            let item: Quiz.Item =
                switch kind {
                case .selectedResponseItem: try Quiz.SelectedResponseItem(from: itemDecoder)
                case .textInputItem: try Quiz.TextInputItem(from: itemDecoder)
                case .listItem: try Quiz.ListItem(from: itemDecoder)
                }
            
            items.append(item)
        }
        
        return items
    }
    
    private enum ItemCodingKeys: String, CodingKey {
        case kind
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ items: [Quiz.Item], forKey key: K) throws {
        var nestedContainer = nestedUnkeyedContainer(forKey: key)
        
        for item in items { // Automatically unboxed?
            try nestedContainer.encode(item)
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
