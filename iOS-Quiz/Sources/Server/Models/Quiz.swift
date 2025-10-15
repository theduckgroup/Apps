import Foundation

struct Quiz: Equatable, Identifiable {
    var id: String
    var name: String
    var code: String
    var emailRecipients: [String]
    var items: [any Item]
    var sections: [Section]
    
    static func ==(_ x: Self, _ y: Self) -> Bool {
        x.id == y.id &&
        x.name == y.name &&
        x.code == y.code &&
        x.emailRecipients == y.emailRecipients &&
        x.items.elementsEqual(y.items, by: areEqual) &&
        x.sections == y.sections
    }
    
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
        emailRecipients = try container.decode([String].self, forKey: .emailRecipients)
        items = try container.decode([Quiz.Item].self, forKey: .items)
        sections = try container.decode([Section].self, forKey: .sections)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encode(emailRecipients, forKey: .emailRecipients)
        try container.encode(items, forKey: .items)
        try container.encode(sections, forKey: .sections)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case code
        case emailRecipients
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
    
    struct SelectedResponseItem: Item, Equatable, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Equatable, Codable {
            var prompt: String
            var options: [Option]
            
            struct Option: Identifiable, Equatable, Codable {
                var id: String
                var value: String
            }
        }
    }
    
    struct TextInputItem: Item, Equatable, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Equatable, Codable {
            var prompt: String
            var layout: Layout
            
            enum Layout: String, Equatable, Codable {
                case inline
                case stack
            }
        }
    }
    
    struct ListItem: Item, Equatable, Codable {
        var id: String
        var kind: ItemKind
        var data: Data
        
        struct Data: Equatable, Codable {
            var prompt: String
            var items: [any Item]
            
            static func ==(x: Self, y: Self) -> Bool {
                x.prompt == y.prompt &&
                x.items.elementsEqual(y.items, by: areEqual)
            }
            
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
    
    enum ItemKind: String, Equatable, Codable {
        case selectedResponseItem
        case textInputItem
        case listItem
    }
    
    struct Section: Equatable, Codable {
        var id: String
        var name: String
        var rows: [Row]
        
        struct Row: Equatable, Codable {
            var itemId: String
        }
    }
}

// Items compare

func areEqual(_ x: Quiz.Item, _ y: Quiz.Item) -> Bool {
    func areEqual<T: Equatable>(_ x: Quiz.Item, _ y: Quiz.Item, ofType: T.Type) -> Bool {
        if let x = x as? T, let y = y as? T {
            return x == y
            
        } else {
            return false
        }
    }
    
    return (
        areEqual(x, y, ofType: Quiz.SelectedResponseItem.self) ||
        areEqual(x, y, ofType: Quiz.TextInputItem.self) ||
        areEqual(x, y, ofType: Quiz.ListItem.self)
    )
}

// Items coding

private extension KeyedDecodingContainer {
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

private extension KeyedEncodingContainer {
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
        emailRecipients: ["john.doe@mail.com"],
        items: [],
        sections: []
    )
}
