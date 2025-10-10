import Foundation
import SwiftUI

struct RespondentView: View {
    @Environment(QuizViewModel.self) var viewModel
    var nextEnabled: Bool
    var onNext: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                        PaperTextField(text: $viewModel.quizResponse.respondent.name)
                            .focused($nameFocused)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Store")
                        PaperTextField(text: $viewModel.quizResponse.respondent.store)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
                .frame(width: horizontalSizeClass == .regular ? 540 : nil)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                }
                .padding(.top, horizontalSizeClass == .regular ? 54 : 0)
                
                PageNavButton("Next", systemImage: "chevron.right") {
                    onNext()
                    // UIApplication.dismissKeyboard()
                }
                .disabled(!nextEnabled)
                .padding(.top, 24)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .onFirstAppear {
            nameFocused = true
        }
    }
}
