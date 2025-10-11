import Foundation
import SwiftUI

struct QuizView: View {
    @State private var viewModel: QuizViewModel
    @State private var pageIndex: Int = 0
    @State private var topBarSize: CGSize?
    @State private var bottomBarSize: CGSize?
    @State private var presentingAppearancePopover = false
    @State private var presentingQuitAlert = false
    @State private var keyboardObserver = KeyboardObserver.shared
    @AppStorage("QuizView:dynamicTypeSizeOverride") var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
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
                NavigationStack {
                    tabView()
                        .overlay(alignment: .bottom, ) {
                            if pageIndex > 0 && !keyboardObserver.isKeyboardVisible {
                                pageNavBar(geometry)
                                    .readSize(assignTo: $bottomBarSize)
                            }
                        }
                        .dynamicTypeSize(dynamicTypeSizeOverride?.dynamicTypeSize ?? systemDynamicTypeSize)
                        .navigationTitle(viewModel.quiz.name)
                        .toolbar {
                            toolbarContent()
                        }
                    // Can apply this to make the overlay ignore keyboard safe area
                    // However that breaks scroll view automatic keyboard avoidance
                    // .ignoresSafeArea([.keyboard], edges: [.bottom])
                }
            }
            .environment(viewModel)
            .onChange(of: pageIndex) {
                UIApplication.dismissKeyboard()
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Quit") {
                presentingQuitAlert = true
            }
            .alert("", isPresented: $presentingQuitAlert) {
                Button("Quit", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Quit without submitting test? You will not be able to return to it.")
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                presentingAppearancePopover = true
                
            } label: {
                Image(systemName: "textformat.el")
                    .font(.subheadline)
            }
            .popover(isPresented: $presentingAppearancePopover) {
                QuizAppearanceView(dynamicTypeSizeOverride: $dynamicTypeSizeOverride)
            }
            
            Button("Submit") {
                handleSubmit()
            }
            .bold()
        }
    }
    
    @ViewBuilder
    private func tabView() -> some View {
        TabView(selection: $pageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                Group {
                    switch page {
                    case .respondentPage:
                        RespondentView(
                            nextEnabled: !respondentIsEmpty,
                            onNext: handleNext
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
                .contentMargins(
                    .vertical,
                    .init(
                        top: topBarSize?.height ?? 0,
                        leading: 0,
                        bottom: (bottomBarSize?.height ?? 0) + 84,
                        trailing: 0
                    ),
                    for: .scrollContent
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        // Enable this breaks the Next/Prev badly!
        // Issue: Next button (on Respondent page) doesn't work after dismissing keyboard
        // Safe area is not even ignored correctly
        // .ignoresSafeArea([.container], edges: [.bottom])
    }
    
    @ViewBuilder
    private func pageNavBar(_ geometry: GeometryProxy) -> some View {
        HStack {
            Button {
                handlePrevious()
                
            } label: {
                Image(systemName: "chevron.left")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
            }
            .disabled(!previousAllowed)
            
            Text("Page \(pageIndex + 1)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.vertical, 15)
            
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
        .padding(.horizontal, 12)
        .glassEffectShim()
        .padding(.horizontal)
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 12 : 21)
        // .padding(.bottom, geometry.safeAreaInsets.bottom)
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
                .tint(.red)
        }
        .environment(AppDefaults())
}
