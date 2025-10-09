import Foundation
import SwiftBSON

extension QuizResponse {
    init(from quiz: Quiz) {
        self.init(
            quiz: quiz,
            respondent: Respondent(),
            createdDate: Date(),
            submittedDate: nil,
            itemResponses: quiz.items.map { .init(from: $0) }
        )
    }
}

extension QuizResponse.ItemResponse {
    init(from item: Quiz.Item) {
        switch item {
        case .selectedResponseItem(let item):
            let response = QuizResponse.SelectedResponseItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind
            )
            
            self = .selectedResponseItemResponse(response)
            
        case .textInputItem(let item):
            let response = QuizResponse.TextInputItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind
            )
            
            self = .textInputItemResponse(response)
            
        case .listItem(let item):
            let subitemResponses = item.data.items.map {
                QuizResponse.ItemResponse(from: $0)
            }
            
            let response = QuizResponse.ListItemResponse(
                id: BSONObjectID().hex,
                itemId: item.id,
                itemKind: item.kind,
                data: .init(
                    itemResponses: subitemResponses
                )
            )
            
            self = .listItemResponse(response)
        }
    }
}
