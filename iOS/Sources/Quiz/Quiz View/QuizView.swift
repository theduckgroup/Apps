import Foundation
import SwiftUI

struct QuizView: View {
    @State private var viewModel: QuizViewModel
    @State private var pageIndex: Int = 2
    @State private var topBarSize: CGSize?
    @State private var bottomBarSize: CGSize?
    @State private var textSize: DynamicTypeSize = .xLarge
    @State private var presentingTextSizeSheet = false
    @Environment(\.dynamicTypeSize) private var defaultTextSize
    @Environment(\.dismiss) private var dismiss
    
    init(quiz: Quiz) {
        viewModel = {
            let response = QuizResponse(from: quiz)
            return QuizViewModel(quizResponse: response)
        }()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                NavigationStack {
                    tabView()
                }
                .overlay(alignment: .bottom) {
                    bottomBar(geometry)
                        .ignoresSafeArea()
                        .readSize(assignTo: $bottomBarSize)
                }
            }
            .environment(viewModel)
            .onAppear {
                textSize = defaultTextSize
            }
            .onChange(of: pageIndex) {
                UIApplication.dismissKeyboard()
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                presentingTextSizeSheet = true
            } label: {
                Image(systemName: "textformat.el")
                    .font(.subheadline)
            }
            .popover(isPresented: $presentingTextSizeSheet) {
                textSizeView()
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
                        RespondentView()
                        
                    case .quizResponsePage(let page):
                        QuizPageView(
                            page: page,
                            nextEnabled: nextEnabled,
                            onNext: handleNext,
                            submitEnabled: pageIndex == viewModel.pages.indices.last!,
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
                .dynamicTypeSize(textSize)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .navigationTitle(viewModel.quiz.name)
        .toolbar {
            toolbarContent()
        }
    }
    
    @ViewBuilder
    private func topBar(_ geometry: GeometryProxy) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .padding(.horizontal, 21)
                    .padding(.vertical, 12)
            }
            .glassEffectShim()
            
            Spacer()
            
            Text(viewModel.quiz.name)
                .font(.title.weight(.medium).leading(.tight))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 27)
                .padding(.vertical, 12)
            
            Spacer()
            
            Button {
                dismiss()
                
            } label: {
                Text("Submit")
                    .bold()
                    .padding(.horizontal, 21)
                    .padding(.vertical, 12)
            }
            .glassEffectShim()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(height: 60)
        // .background(Color(UIColor.systemBackground))
        .background(Color.red)
    }
    
    @ViewBuilder
    private func textSizeView() -> some View {
        VStack(alignment: .leading) {
            Text("Text Size")
            
            let dynamicTypeSizes: [DynamicTypeSize] = [
                .xSmall,
                .small,
                .medium,
                .large,
                .xLarge,
                .xxLarge,
                .xxxLarge,
                // .accessibility1,
                // .accessibility2,
                // .accessibility3,
                // .accessibility4,
                // .accessibility5
            ]
            
            let enumeratedSizes = dynamicTypeSizes.enumerated()
            let map: [Int: DynamicTypeSize] = .init(uniqueKeysWithValues: enumeratedSizes.map { ($0, $1) })
            let reverseMap: [DynamicTypeSize: Int] = .init(uniqueKeysWithValues: enumeratedSizes.map { ($1, $0) })
            let keys = map.keys.sorted()
            let minValue = keys.first!
            let maxValue = keys.last!
            
            let valueBinding = Binding<Double> {
                Double(reverseMap[textSize] ?? keys.last!)
            } set: {
                textSize = map[Int($0.rounded())]!
            }
            
            Slider(
                value: valueBinding,
                in: Double(minValue)...Double(maxValue),
                step: 1,
                label: { Text("Font Size") },
                minimumValueLabel: { },
                maximumValueLabel: { }
            )
            .frame(width: 240)
            
            Button("Reset Default") {
                textSize = defaultTextSize
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
    }
    
    @ViewBuilder
    private func bottomBar(_ geometry: GeometryProxy) -> some View {
        HStack {
            Button {
                handlePrevious()
                
            } label: {
                Image(systemName: "chevron.left")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
            }
            .glassEffectShim()
            .opacity(previousEnabled ? 1 : 0)
            
            Spacer()
            
            Text("Page \(pageIndex + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 150)
                .padding(.vertical, 15)
                .glassEffectShim()
            
            Spacer()
            
            Button {
                handleNext()
                
            } label: {
                Image(systemName: "chevron.right")
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
            }
            .glassEffectShim()
            .opacity(nextEnabled ? 1 : 0)
        }
        .padding()
        // .padding(.bottom, geometry.safeAreaInsets.bottom)
    }
        
    private var previousEnabled: Bool {
        pageIndex > 0
    }
    
    private func handlePrevious() {
        withAnimation {
            pageIndex -= 1
        }
    }
    
    private var nextEnabled: Bool {
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
    
    @ViewBuilder
    func quizPageScrollViewContentMargins() -> some View {
        contentMargins(
            // Note: scroll views inside QuizViews don't ignore safe area
            .vertical,
            .init(
                top: 100,
                leading: 0,
                bottom: 100,
                trailing: 0
            ),
            for: .scrollContent
        )
    }
    
    func modified<R: View>(@ViewBuilder _ with: (Self) -> R) -> R {
        with(self)
    }
}

#Preview {
    @Previewable @State var quiz: Quiz?
    
    Text("Loading...")
        .onAppear {
            Task {
                do {
                    let mockQuiz = try await Server.mockQuiz()
                    quiz = mockQuiz
                    
                } catch {
                    logger.error("Unable to get mock quiz: \(error)")
                }
            }
        }
        .fullScreenCover(item: $quiz) { quiz in
            QuizView(quiz: quiz)
                .tint(.red)
        }
}
