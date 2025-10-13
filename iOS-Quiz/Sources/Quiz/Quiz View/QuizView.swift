import Foundation
import SwiftUI

struct QuizView: View {
    @State private var viewModel: QuizViewModel
    @State private var pageIndex: Int = 0
    @State private var topBarSize: CGSize?
    @State private var bottomBarSize: CGSize?
    @State private var didFinishRespondent = false
    @State private var presentingAppearancePopover = false
    @State private var ps = PresentationState()
    @AppStorage("QuizView:dynamicTypeSizeOverride") var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    init(quiz: Quiz) {
        viewModel = {
            let response = QuizResponse(from: quiz)
            return QuizViewModel(quizResponse: response)
        }()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
//                NavigationStack {
//                VStack {
                    pagesView(geometry)
                        .overlay(alignment: .top) {
                            topBar()
                                .readSize(assignTo: $topBarSize)
                        }
//                        .overlay(alignment: .bottom) {
//                            if didFinishRespondent { // && !keyboardObserver.isKeyboardVisible
//                                pageNavBar(geometry)
//                                    .readSize(assignTo: $bottomBarSize)
//                            }
//                        }
                        .dynamicTypeSize(dynamicTypeSizeOverride?.dynamicTypeSize ?? systemDynamicTypeSize)
//                        .navigationTitle(viewModel.quiz.name)
//                        .toolbar {
//                            toolbarContent()
//                        }
                    // Can apply this to make the overlay ignore keyboard safe area
                    // However that breaks scroll view automatic keyboard avoidance
                    // .ignoresSafeArea([.keyboard], edges: [.bottom])
//                }
            }
            .presentations(ps)
            .environment(viewModel)
            .onChange(of: pageIndex) {
                UIApplication.dismissKeyboard()
            }
        }
    }
    
//    @ToolbarContentBuilder
//    private func toolbarContent() -> some ToolbarContent {
//        ToolbarItem(placement: .topBarLeading) {
//            Button("Quit") {
//                presentingQuitAlert = true
//            }
//            .alert("", isPresented: $presentingQuitAlert) {
//                Button("Quit", role: .destructive) {
//                    dismiss()
//                }
//            } message: {
//                Text("Quit without submitting test? You will not be able to return to it.")
//            }
//        }
//        
//        ToolbarItemGroup(placement: .topBarTrailing) {
//            Button {
//                presentingAppearancePopover = true
//                
//            } label: {
//                Image(systemName: "textformat.el")
//                    .font(.subheadline)
//            }
//            .popover(isPresented: $presentingAppearancePopover) {
//                QuizAppearanceView(dynamicTypeSizeOverride: $dynamicTypeSizeOverride)
//            }
//            
//            Button("Submit") {
//                handleSubmit()
//            }
//            .bold()
//        }
//    }
    
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
            QuizAppearanceView(dynamicTypeSizeOverride: $dynamicTypeSizeOverride)
        }
    }
    
    @ViewBuilder
    private func submitButton() -> some View {
        Button {
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
    
    @ViewBuilder
    private func pagesView(_ geometry: GeometryProxy) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { pageIndex, page in
                    viewForPage(page)
                        .frame(width: geometry.size.width)
                        .id(pageIndex)
                }
            }
        }
        .contentMargins(
            .vertical,
            .init(
                top: topBarSize?.height ?? 0,
                leading: 0,
                bottom: (bottomBarSize?.height ?? 0) + 120, // Enough to see the next text input item
                trailing: 0
            ),
            for: .scrollContent
        )
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
    
    @ScaledMetric private var pageSpacing = 15

    @ViewBuilder
    private func viewForPage(_ page: QuizViewModel.Page) -> some View {
        Group {
            switch page {
            case .respondentPage:
                RespondentView(
                    nextEnabled: !respondentIsEmpty,
                    onNext: {
                        didFinishRespondent = true
                        handleNext()
                    }
                )
                
            case .quizResponsePage(let page):
                QuizPageView(
                    page: page,
                    nextVisible: nextAllowed,
                    onNext: handleNext,
                    submitVisible: pageIndex == viewModel.pages.indices.last!,
                    onSubmit: handleSubmit
                )
            }
        }
//        .contentMargins(
//            .vertical,
//            .init(
//                top: topBarSize?.height ?? 0,
//                leading: 0,
//                bottom: (bottomBarSize?.height ?? 0) + 84,
//                trailing: 0
//            ),
//            for: .scrollContent
//        )
    }
    
    @ViewBuilder
    private func pageNavBar(_ geometry: GeometryProxy) -> some View {
        HStack {
            Button {
                handlePrevious()
                
            } label: {
                Image(systemName: "chevron.left")
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .disabled(!previousAllowed)
            
            Text("Page \(pageIndex + 1)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            
            Button {
                handleNext()
                
            } label: {
                Image(systemName: "chevron.right")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
            }
            .disabled(!nextAllowed)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .paperCapsuleBackground()
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 12 : 21)
    }
    
    private var respondentIsEmpty: Bool {
        viewModel.quizResponse.respondent.name.isEmpty ||
        viewModel.quizResponse.respondent.store.isEmpty
    }
        
    private var previousAllowed: Bool {
        pageIndex > 0
    }
    
    private func handlePrevious() {
        withAnimation {
            pageIndex -= 1
        }
    }
    
    private var nextAllowed: Bool {
        pageIndex < viewModel.pages.indices.last!
    }
    
    private func handleNext() {
        withAnimation {
            pageIndex += 1
        }
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
                ps.presentAlert(error: error)
            }
        }
    }
}

extension QuizView {
    enum TabViewSelection: Hashable {
        case respondentPage
        case page(Int)
    }
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
            QuizView(quiz: quiz)
                .tint(.blue)
        }
        .environment(AppDefaults())
}
