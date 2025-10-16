import Foundation
import SwiftUI
import Common
import CommonUI

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
            let response = QuizResponse(from: quiz, store: Auth.shared.user!.name)
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
            .overlay(alignment: .top) {
                topBar()
                    .readSize(assignTo: $topBarSize)
            }
            .dynamicTypeSize(dynamicTypeSizeOverride?.dynamicTypeSize ?? systemDynamicTypeSize)
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
            
            HStack {
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
            ps.presentAlert(message: "Quit without submitting test? You will not be able to return to it.") {
                Button("Quit", role: .destructive) {
                    dismiss()
                }
            }
            
        } label: {
            Text("Quit")
        }
        .buttonStyle(.paper(wide: true, maxHeight: .infinity))
    }
    
    @ViewBuilder
    private func appearanceButton() -> some View {
        Button {
            presentingAppearancePopover = true
            
        } label: {
            Image(systemName: "textformat.el")
        }
        .buttonStyle(.paper(wide: true, maxHeight: .infinity))
        .popover(isPresented: $presentingAppearancePopover) {
            QRAppearanceView(dynamicTypeSizeOverride: $dynamicTypeSizeOverride)
        }
    }
    
    @ViewBuilder
    private func submitButton() -> some View {
        Button {
            UIApplication.dismissKeyboard()
            
            ps.presentAlert(message: "Submit test?") {
                Button("Submit") {
                    handleSubmit()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            
        } label: {
            Text("Submit")
        }
        .buttonStyle(.paper(prominent: true, wide: true, maxHeight: .infinity))
    }
    
    private func handleSubmit() {
        Task {
            do {
                ps.presentProgressHUD(title: "Submitting")
                
                viewModel.quizResponse.submittedDate = Date()
                
                try await Task.sleep(for: .seconds(2))
                try await API.shared.submitQuizResponse(viewModel.quizResponse)
                
                ps.dismiss()
                
                ps.presentAlert(title: "Test submitted") {
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
    
    /*
    @ViewBuilder
    private func oldPagesView(_ geometry: GeometryProxy) -> some View {
        // PagesView(selection: $pageIndex, values: Array(viewModel.pages.indices)) { pageIndex in
        TabView(selection: $pageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { pageIndex, page in
                viewForPage(page)
                    .frame(width: geometry.size.width)
                    .id(pageIndex)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        // Enable this breaks the Next/Prev badly!
        // Issue: Next button (on Respondent page) doesn't work after dismissing keyboard
        // Safe area is not even ignored correctly
        // .ignoresSafeArea([.container], edges: [.bottom])
    }
    */
}

extension View {
    @ViewBuilder
    func glassEffectShim() -> some View {
        if #available(iOS 26, *) {
            glassEffect()
        } else {
            background(.regularMaterial)
                .clipShape(Capsule())
        }
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
                .tint(.blue)
        }
        .environment(AppDefaults())
}
