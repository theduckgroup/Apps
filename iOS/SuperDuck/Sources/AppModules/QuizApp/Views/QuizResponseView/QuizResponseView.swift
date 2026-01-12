import Foundation
import SwiftUI
import Common
import CommonUI

struct QuizResponseView: View {
    @State var viewModel: QuizResponseViewModel
    @State var topBarSize: CGSize?
    @State var presentingAppearancePopover = false
    @State var ps = PresentationState()
    @Environment(API.self) var api
    @Environment(QuizAppDefaults.self) var defaults
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    
    init(quiz: Quiz, user: User) {
        viewModel = {
            let user = QuizResponse.User(from: user)
            let response = QuizResponse(from: quiz, user: user)
            return QuizResponseViewModel(quizResponse: response)
        }()
    }
    
    var body: some View {
        NavigationStack {
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
            // .scrollDismissesKeyboard(.immediately)
            .modified {
                if let dynamicTypeSizeOverride = defaults.dynamicTypeSizeOverride {
                    $0.dynamicTypeSize(dynamicTypeSizeOverride.dynamicTypeSize)
                } else {
                    $0
                }
            }
            .navigationTitle("")
            .toolbar { toolbarContent() }
        }
        .preferredColorScheme(defaults.colorSchemeOverride?.colorScheme)
        .presentations(ps)
        .environment(viewModel)
        .interactiveDismissDisabled()
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            quitButton()
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            appearanceButton()
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            submitButton()
        }
    }
    
    @ViewBuilder
    private func quitButton() -> some View {
        Button {
            UIApplication.shared.dismissKeyboard()
            
            ps.presentAlert(title: "Quit", message: "Quit without submitting test? You will not be able to return to it.") {
                Button("Stay", role: .cancel) {}

                Button("Quit", role: .destructive) {
                    dismiss()
                }
            }
            
        } label: {
            Text("Cancel")
            // Image(systemName: "xmark")
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.automatic)
    }
    
    @ViewBuilder
    private func appearanceButton() -> some View {
        Button {
            UIApplication.shared.dismissKeyboard()
            
            presentingAppearancePopover = true
            
        } label: {
            Image(systemName: "textformat.el")
                .padding(.horizontal, 3)
        }
        .popover(isPresented: $presentingAppearancePopover) {
            QRAppearanceView()
        }
    }
    
    @ViewBuilder
    private func submitButton() -> some View {
        Button {
            UIApplication.shared.dismissKeyboard()
            
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
                .bold()
        }
        .modified {
            if #available(iOS 26, *) {
                $0.buttonStyle(.glassProminent)
            } else {
                $0.buttonStyle(.borderedProminent)
            }
        }
        
    }
    
    private func handleSubmit() {
        Task {
            do {
                ps.presentProgressHUD(title: "Submitting Test...")
                
                viewModel.submittedDate = Date()
                
                try await Task.sleep(for: .seconds(0.5))
                try await api.submitQuizResponse(viewModel.quizResponse)
                
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
                
        if debugging {
            return nil
        }
        
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
                    quiz = try await API.localWithMockAuth.quiz()
                    
                } catch {
                    logger.error("Unable to get mock quiz: \(error)")
                }
            }
        }
        .fullScreenCover(item: $quiz) { quiz in
            QuizResponseView(quiz: quiz, user: .mock)
                .previewEnvironment()
        }
        
}
