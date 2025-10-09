import Foundation
import SwiftUI

@Observable
class QuizViewModel {
    var quizResponse: QuizResponse
    var pages: [Page]
    
    init(quizResponse: QuizResponse) {
        self.quizResponse = quizResponse
        self.pages = Self.pagesFromQuizResponse(quizResponse)
    }
    
    private static func pagesFromQuizResponse(_ quizResponse: QuizResponse) -> [Page] {
        let quiz = quizResponse.quiz
        var pages: [Page] = []
        var currentPageRows: [Row] = []
        
        func endPage() {
            pages.append(.init(rows: currentPageRows))
            currentPageRows.removeAll()
        }
        
        for section in quiz.sections {
            // Section header will go here
            
            for row in section.rows {
                let itemResponse = quizResponse.itemResponses.first { $0.itemId == row.itemId }
                
                guard let itemResponse else {
                    assertionFailure()
                    continue
                }
            
                if currentPageRows.count > quiz.itemsPerPage {
                    endPage()
                }
                
                currentPageRows.append(.itemResponse(id: itemResponse.id))
            }
            
            endPage()
        }
        
        return pages
    }
    
    var quiz: Quiz {
        quizResponse.quiz
    }
    
    func itemResponseBindingForID(_ id: String) -> Binding<QuizResponse.ItemResponse> {
        let index = quizResponse.itemResponses.firstIndex { $0.id == id }!
        
        let binding = Binding {
            self.quizResponse.itemResponses[index]
        } set: {
            self.quizResponse.itemResponses[index] = $0
        }
        
        return binding
    }
}

extension QuizViewModel {
    struct Page: Identifiable {
        let id = UUID()
        let rows: [Row]
    }
    
    enum Row {
        // Section header will go here
        
        case itemResponse(id: String)
    }
}
