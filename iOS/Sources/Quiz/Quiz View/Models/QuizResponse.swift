import Foundation

struct QuizResponse {
    let quiz: Quiz
    var respondent: Respondent
    var createdDate: Date
    var submittedDate: Date?
    var itemResponses: [ItemResponse]
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
    struct Respondent: Encodable {
        var name: String = ""
        var store: String = ""
    }
    
    protocol ItemResponse: Encodable {
        var id: String { get }
        var itemId: String { get }
    }
    
    struct SelectedResponseItemResponse: ItemResponse, Encodable {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data: Encodable {
            var selectedOptions: [SelectedOption] = []
            
            struct SelectedOption: Encodable {
                var id: String
                var value: String
            }
        }
    }
    
    struct TextInputItemResponse: ItemResponse, Encodable {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data: Encodable {
            var value: String = ""
        }
    }
    
    struct ListItemResponse: ItemResponse {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data: Data
        
        struct Data: Encodable {
            var itemResponses: [any ItemResponse]
            
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

// ItemResponse Coding

extension KeyedEncodingContainer {
    mutating func encode(_ itemResponses: [QuizResponse.ItemResponse], forKey key: K) throws {
        var nestedContainer = nestedUnkeyedContainer(forKey: key)
        
        for itemResponse in itemResponses { // Automatically unboxed?
            try nestedContainer.encode(itemResponse)
        }
    }
}
