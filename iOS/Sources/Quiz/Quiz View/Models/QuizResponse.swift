import Foundation

struct QuizResponse {
    let quiz: Quiz
    var respondent: Respondent
    var createdDate: Date
    var submittedDate: Date?
    var itemResponses: [ItemResponse]
}

extension QuizResponse {
    struct Respondent {
        var name: String = ""
        var store: String = ""
    }
    
    enum ItemResponse {
        case selectedResponseItemResponse(SelectedResponseItemResponse)
        case textInputItemResponse(TextInputItemResponse)
        case listItemResponse(ListItemResponse)
        
        var id: String {
            switch self {
            case .selectedResponseItemResponse(let item): item.id
            case .textInputItemResponse(let item): item.id
            case .listItemResponse(let item): item.id
            }
        }
        
        var itemId: String {
            switch self {
            case .selectedResponseItemResponse(let item): item.itemId
            case .textInputItemResponse(let item): item.itemId
            case .listItemResponse(let item): item.itemId
            }
        }
        
        func `as`<T>(_ type: T.Type) -> T {
            if T.self == SelectedResponseItemResponse.self {
                guard case .selectedResponseItemResponse(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            if T.self == TextInputItemResponse.self {
                guard case .textInputItemResponse(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            if T.self == ListItemResponse.self {
                guard case .listItemResponse(let value) = self else {
                    fatalError()
                }
                
                return value as! T
            }
            
            preconditionFailure()
        }
    }
    
    struct SelectedResponseItemResponse {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data {
            var selectedOptions: [SelectedOption] = []
            
            struct SelectedOption {
                var id: String
            }
        }
    }
    
    struct TextInputItemResponse {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data = Data()
        
        struct Data {
            var value: String = ""
        }
    }
    
    struct ListItemResponse {
        let id: String
        let itemId: String
        let itemKind: Quiz.ItemKind
        var data: Data
        
        struct Data {
            var itemResponses: [ItemResponse]
        }
    }
}
