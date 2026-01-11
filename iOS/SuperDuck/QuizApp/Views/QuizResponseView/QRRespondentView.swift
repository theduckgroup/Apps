import Foundation
import SwiftUI
import CommonUI

struct QRRespondentView: View {
    @Environment(QuizResponseViewModel.self) var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(alignment: .leading, spacing: 24) {
            Text(viewModel.quiz.name)
                .font(.title)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                    PaperTextField(text: $viewModel.respondent.name, multiline: false, textColor: .blue)
                        .focused($nameFocused)
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Store")
                    PaperTextField(text: $viewModel.respondent.store, multiline: false, textColor: .blue)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .onFirstAppear {
            nameFocused = true
        }
    }
}

