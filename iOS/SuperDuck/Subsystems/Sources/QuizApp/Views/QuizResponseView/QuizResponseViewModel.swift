import Foundation
import SwiftUI

/// Quiz response view model.
///
/// This takes a `QuizResponse`, breaks it down into individual parts. Main purpose is to have
/// separate observable objects for each items, otherwise it slows down view update because the
/// `QuizResponse` is a fairly large object.
///
/// Breaking `QuizResponse` down also simplifies the code around sections -- sections are
/// pre-computed when initializing the view model, rather than being resolved dynamically during
/// view update (doing so requires having a method to compute the binding for each row/item).
@Observable
class QuizResponseViewModel {
    let quiz: Quiz
    let user: QuizResponse.User
    var respondent: QuizResponse.Respondent
    var createdDate: Date
    var submittedDate: Date?
    var sections: [SectionViewModel] = []
    
    /// Initializes from a quiz response. The quiz response is broken down into view model properties.
    init(quizResponse: QuizResponse) {
        self.quiz = quizResponse.quiz
        self.user = quizResponse.user
        self.respondent = quizResponse.respondent
        self.createdDate = quizResponse.createdDate
        self.submittedDate = quizResponse.submittedDate
        
        let itemIDToItemRepsonseIndexMap: [String: QuizResponse.ItemResponse] = {
            let itemIDs = quizResponse.quiz.items.map(\.id)
            
            let itemResponseIndexes = itemIDs.map { itemID in
                quizResponse.itemResponses.first { $0.itemId == itemID }!
            }
            
            return Dictionary(uniqueKeysWithValues: zip(itemIDs, itemResponseIndexes))
        }()
        
        self.sections = quizResponse.quiz.sections.map { quizSection in
            let itemResponseVMs = quizSection.rows.map { row in
                let itemResponse = itemIDToItemRepsonseIndexMap[row.itemId]!
                return ItemResponseViewModel(data: itemResponse)
            }
            
            return SectionViewModel(id: quizSection.id, itemResponses: itemResponseVMs)
        }
    }
    
    /// Quiz response. Computed from the view model's properties.
    var quizResponse: QuizResponse {
        let itemResponses: [QuizResponse.ItemResponse] = {
            var itemIDToItemResponsesMap: [String: QuizResponse.ItemResponse] = [:]
            
            for section in sections {
                for itemResponseVM in section.itemResponses {
                    itemIDToItemResponsesMap[itemResponseVM.data.itemId] = itemResponseVM.data
                }
            }
            
            return quiz.items.map { itemIDToItemResponsesMap[$0.id]! }
        }()
        
        let quizResponse = QuizResponse(
            quiz: quiz,
            user: user,
            respondent: respondent,
            createdDate: createdDate,
            submittedDate: submittedDate,
            itemResponses: itemResponses
        )
        
        return quizResponse
    }
}

extension QuizResponseViewModel {
    @Observable
    class SectionViewModel {
        var id: String
        var itemResponses: [ItemResponseViewModel]
        
        init(id: String, itemResponses: [ItemResponseViewModel]) {
            self.id = id
            self.itemResponses = itemResponses
        }
    }
    
    @Observable
    class ItemResponseViewModel {
        var data: QuizResponse.ItemResponse
        
        init(data: QuizResponse.ItemResponse) {
            self.data = data
        }
    }
}
