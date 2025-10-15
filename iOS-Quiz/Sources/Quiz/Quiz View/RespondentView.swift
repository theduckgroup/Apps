import Foundation
import SwiftUI

struct RespondentView: View {
    @Environment(QuizViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(alignment: .leading, spacing: 24) {
            Text(viewModel.quiz.name)
                .font(.title)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                    PaperTextField(text: $viewModel.quizResponse.respondent.name)
                        .focused($nameFocused)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Store")
                    PaperTextField(text: $viewModel.quizResponse.respondent.store)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onFirstAppear {
            nameFocused = true
        }
    }
}

