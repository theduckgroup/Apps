import Foundation
import SwiftUI

@Observable
class QuizViewModel {
    var quizResponse: QuizResponse
    private let itemIDToItemRepsonseIndexMap: [String: Int]
    private let itemResponseIDToIndexMap: [String: Int]
    
    init(quizResponse: QuizResponse) {
        self.quizResponse = quizResponse
        
        do {
            // Item ID -> Item response index map
            
            let itemIDs = quizResponse.quiz.items.map(\.id)
            
            let itemResponseIndexes = itemIDs.map { itemID in
                quizResponse.itemResponses.firstIndex { $0.itemId == itemID }!
            }
            
            itemIDToItemRepsonseIndexMap = Dictionary(uniqueKeysWithValues: zip(itemIDs, itemResponseIndexes))
        }
        
        do {
            // Item response -> Item repsonse index map
            
            let indexesWithValues = quizResponse.itemResponses.map(\.id).enumerated()
            let valuesWithIndexes = indexesWithValues.map { ($1, $0) }
            itemResponseIDToIndexMap = Dictionary(uniqueKeysWithValues: valuesWithIndexes)
        }
    }
    
    var quiz: Quiz {
        quizResponse.quiz
    }
    
    func itemResponseForItemID(_ itemID: String) -> QuizResponse.ItemResponse {
        let index = itemIDToItemRepsonseIndexMap[itemID]!
        return quizResponse.itemResponses[index]
    }
    
    func itemResponseBindingForID(_ itemResponseID: String) -> Binding<QuizResponse.ItemResponse> {
        let index = itemResponseIDToIndexMap[itemResponseID]!
        // let index = quizResponse.itemResponses.firstIndex { $0.id == id }!
        
        let binding = Binding {
            self.quizResponse.itemResponses[index]
        } set: {
            self.quizResponse.itemResponses[index] = $0
        }
        
        return binding
    }
}
