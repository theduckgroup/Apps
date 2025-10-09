import Foundation
import SwiftUI

struct QuizView: View {
    @State var viewModel: QuizViewModel
    
    init(quiz: Quiz) {
        viewModel = {
            let response = QuizResponse(from: quiz)
            return QuizViewModel(quizResponse: response)
        }()
    }
    
    var body: some View {
        TabView {
            RespondentView()
            
            ForEach(viewModel.pages) { page in
                QuizPageView(page: page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .environment(viewModel)
    }
}
