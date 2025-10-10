import Foundation
import SwiftUI

struct RespondentView: View {
    @Environment(QuizViewModel.self) var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Name")
                    PaperTextField(text: $viewModel.quizResponse.respondent.name)
                }
                
                VStack(alignment: .leading) {
                    Text("Store")
                    PaperTextField(text: $viewModel.quizResponse.respondent.store)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
