import Foundation
import Supabase
import SwiftBSON

extension QuizResponse {
    init(from quiz: Quiz, store: String) {
        self.init(
            quiz: quiz,
            respondent: Respondent(store: store),
            createdDate: Date(),
            submittedDate: nil,
            itemResponses: quiz.items.map(Self.createItemResponseFromItem)
        )
    }
    
    private static func createItemResponseFromItem(_ item: Quiz.Item) -> QuizResponse.ItemResponse {
        switch item {
        case let item as Quiz.SelectedResponseItem:
            return QuizResponse.SelectedResponseItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind
            )
            
        case let item as Quiz.TextInputItem:
            return QuizResponse.TextInputItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind
            )
            
        case let item as Quiz.ListItem:
            let subitemResponses = item.data.items.map(createItemResponseFromItem)
            
            return QuizResponse.ListItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind,
                data: .init(
                    itemResponses: subitemResponses
                )
            )
            
        default:
            preconditionFailure()
        }
    }
}
