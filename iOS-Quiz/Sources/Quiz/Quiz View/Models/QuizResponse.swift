import Foundation

struct QuizResponse: Equatable {
    let quiz: Quiz
    var respondent: Respondent
    var createdDate: Date
    var submittedDate: Date?
    var itemResponses: [ItemResponse]
    
    static func ==(_ x: Self, _ y: Self) -> Bool {
        x.quiz == y.quiz &&
        x.respondent == y.respondent &&
        x.createdDate == y.createdDate &&
        x.submittedDate == y.submittedDate &&
        x.itemResponses.elementsEqual(y.itemResponses, by: areEqual)
    }
}

extension QuizResponse: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quiz, forKey: .quiz)
        try container.encode(respondent, forKey: .respondent)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(submittedDate, forKey: .submittedDate)
        try container.encode(itemResponses, forKey: .itemResponses)
    }
    
    enum CodingKeys: String, CodingKey {
        case quiz
        case respondent
        case createdDate
        case submittedDate
        case itemResponses
    }
}

extension QuizResponse {
    struct Respondent: Equatable, Encodable {
        var name: String = ""
        var store: String = ""
    }
    
    protocol ItemResponse: Encodable {
        var id: String { get }
        var itemId: String { get }
    }
    
    struct SelectedResponseItemResponse: ItemResponse, Equatable, Encodable {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data: Equatable, Encodable {
            var selectedOptions: [SelectedOption] = []
            
            struct SelectedOption: Equatable, Encodable {
                var id: String
                var value: String
            }
        }
    }
    
    struct TextInputItemResponse: ItemResponse, Equatable, Encodable {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data: Equatable, Encodable {
            var value: String = ""
        }
    }
    
    struct ListItemResponse: ItemResponse, Equatable, Encodable {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data: Data
        
        struct Data: Equatable, Encodable {
            var itemResponses: [any ItemResponse]
            
            static func ==(_ x: Self, _ y: Self) -> Bool {
                x.itemResponses.elementsEqual(y.itemResponses, by: areEqual)
            }
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(itemResponses, forKey: .itemResponses)
            }
            
            enum CodingKeys: CodingKey {
                case itemResponses
            }
        }
    }
}

// ItemResponse equal

func areEqual(_ x: QuizResponse.ItemResponse, _ y: QuizResponse.ItemResponse) -> Bool {
    func areEqual<T: Equatable>(_ x: QuizResponse.ItemResponse, _ y: QuizResponse.ItemResponse, ofType: T.Type) -> Bool {
        if let x = x as? T, let y = y as? T {
            return x == y
            
        } else {
            return false
        }
    }
    
    return (
        areEqual(x, y, ofType: QuizResponse.SelectedResponseItemResponse.self) ||
        areEqual(x, y, ofType: QuizResponse.TextInputItemResponse.self) ||
        areEqual(x, y, ofType: QuizResponse.ListItemResponse.self)
    )
}

// ItemResponse Coding

private extension KeyedEncodingContainer {
    mutating func encode(_ itemResponses: [QuizResponse.ItemResponse], forKey key: K) throws {
        var nestedContainer = nestedUnkeyedContainer(forKey: key)
        
        for itemResponse in itemResponses { // Automatically unboxed?
            try nestedContainer.encode(itemResponse)
        }
    }
}
