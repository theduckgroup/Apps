import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct QuizResponseView: View {
    @State private var viewModel: QuizResponseViewModel
    @State private var topBarSize: CGSize?
    @State private var presentingAppearancePopover = false
    @State private var ps = PresentationState()
    @AppStorage("QuizResponseView:dynamicTypeSizeOverride") var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    init(quiz: Quiz) {
        viewModel = {
            let user = QuizResponse.User(from: Auth.shared.user!)
            let response = QuizResponse(from: quiz, user: user)
            return QuizResponseViewModel(quizResponse: response)
        }()
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    QRRespondentView()
                    QRItemsView()
                }
            }
            .contentMargins(
                .vertical,
                .init(
                    top: topBarSize?.height ?? 0,
                    leading: 0,
                    bottom: 120, // Enough to see the next text input item
                    trailing: 0
                ),
                for: .scrollContent
            )
            .scrollDismissesKeyboard(.immediately)
            .dynamicTypeSize(dynamicTypeSizeOverride?.dynamicTypeSize ?? systemDynamicTypeSize)
            .overlay(alignment: .top) {
                topBar()
                    .readSize(assignTo: $topBarSize)
            }
        }
        .presentations(ps)
        .environment(viewModel)
    }
    
    // Top bar
    
    @ViewBuilder
    private func topBar() -> some View {
        HStack(spacing: 18) {
            quitButton()
            
            //            if horizontalSizeClass == .regular {
            //                Text(viewModel.quiz.name)
            //                    .fontWeight(.bold)
            //                    .frame(minHeight: 44)
            //                    .padding(.horizontal, 24)
            //                    .background {
            //                        Capsule()
            //                            .fill(.background)
            //                    }
            //                    .glassEffectShim()
            //            }
            
            Spacer()
            
            HStack(spacing: 15) {
                appearanceButton()
                submitButton()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }
    
    @ViewBuilder
    private func quitButton() -> some View {
        Button {
            UIApplication.dismissKeyboard()
            
            ps.presentAlert(message: "Quit without submitting test? You will not be able to return to it.") {
                Button("Stay", role: .cancel) {}

                Button("Quit", role: .destructive) {
                    dismiss()
                }
            }
            
        } label: {
            Text("Quit")
                .padding(.horizontal, 9)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.paper)
    }
    
    @ViewBuilder
    private func appearanceButton() -> some View {
        Button {
            UIApplication.dismissKeyboard()
            
            presentingAppearancePopover = true
            
        } label: {
            Image(systemName: "textformat.el")
                .padding(.horizontal, 3)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.paper)
        .popover(isPresented: $presentingAppearancePopover) {
            QRAppearanceView(dynamicTypeSizeOverride: $dynamicTypeSizeOverride)
        }
    }
    
    @ViewBuilder
    private func submitButton() -> some View {
        Button {
            UIApplication.dismissKeyboard()
            
            if let error = validateSubmit() {
                ps.presentAlert(title: "Error", message: error, actions: {})
                return
            }
            
            ps.presentAlert(title: "Submit test?") {
                Button("Submit") {
                    handleSubmit()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            
        } label: {
            Text("Submit")
                .padding(.horizontal, 9)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.paperProminent)
    }
    
    private func handleSubmit() {
        Task {
            do {
                ps.presentProgressHUD(title: "Submitting Test...")
                
                viewModel.submittedDate = Date()
                
                try await Task.sleep(for: .seconds(2))
                try await API.shared.submitQuizResponse(viewModel.quizResponse)
                
                ps.dismiss()
                
                ps.presentAlert(title: "Test Submitted") {
                    Button("Close") {
                        dismiss()
                    }
                }
                
            } catch {
                ps.dismiss()
                
                ps.presentAlert(error: error)
            }
        }
    }
    
    private func validateSubmit() -> String? {
        guard viewModel.respondent.name != "" else {
            return "Please enter your name"
        }
        
        guard viewModel.respondent.name != "" else {
            return "Please enter store name"
        }
        
        if let error = validateAnswers() {
            return error
        }
        
        return nil
    }
    
    private func validateAnswers() -> String? {
        // Rewrite this if multiple sections are needed
        
        let indexes: [Int] = viewModel.sections.flatMap { section in
            section.itemResponses.enumerated().compactMap { index, itemResponse in
                let itemResponse = itemResponse.data
                return itemResponse.isAnswered ? nil : index
            }
        }
        
        var ranges: [ClosedRange<Int>] = []
        
        for index in indexes {
            guard let last = ranges.last else {
                ranges.append(index...index)
                continue
            }
            
            if last.upperBound == index - 1 {
                ranges[ranges.count - 1] = last.lowerBound...index
                
            } else {
                ranges.append(index...index)
            }
        }
        
        if debugging {
            return nil
        }
        
        if ranges.count > 0 {
            func format(_ range: ClosedRange<Int>) -> String {
                if range.lowerBound == range.upperBound {
                    "\(range.lowerBound + 1)"
                } else {
                    "\(range.lowerBound + 1)-\(range.upperBound + 1)"
                }
            }
            
            let formattedRanges = ranges.map(format).joined(separator: ", ")
            
            let noun = ranges.count == 1 && ranges[0].count == 1 ? "question" : "questions"
            
            return """
            All questions must be answered before submitting.
            
            Please answer \(noun) \(formattedRanges).
            """
        }
        
        return nil
    }
}

#Preview {
    @Previewable @State var quiz: Quiz?
    
    Text("Loading...")
        .onAppear {
            Task {
                do {
                    quiz = try await API.shared.mockQuiz()
                    
                } catch {
                    logger.error("Unable to get mock quiz: \(error)")
                }
            }
        }
        .fullScreenCover(item: $quiz) { quiz in
            QuizResponseView(quiz: quiz)
                .tint(.theme)
        }
        .environment(AppDefaults())
}
