import Foundation
import SwiftUI

struct RespondentView: View {
    @Environment(QuizViewModel.self) var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(alignment: .leading) {
            VStack {
                Text("Name")
                PaperTextField(text: $viewModel.quizResponse.respondent.name)
            }
            
            VStack {
                Text("Store")
                PaperTextField(text: $viewModel.quizResponse.respondent.store)
            }
        }
    }
}
