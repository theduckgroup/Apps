import Foundation
public import SwiftUI
import Common
import CommonUI

public struct QuizAppView: View {
    @State var quizFetcher = ValueFetcher<Quiz>()
    // @AppStorage("App:persistedQuizName") var persistedQuizName: String = ""
    @State var presentedQuiz: Quiz?
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("FOH Test")
        }
        .fullScreenCover(item: $presentedQuiz) { quiz in
            QuizResponseView(quiz: quiz, user: auth.user!)
        }
        .onFloatingTabSelected {
            fetchQuiz()
        }
        .onSceneBecomeActive {
            fetchQuiz()
        }
        .onReceive(api.eventHub.quizzesChanged) {
            fetchQuiz()
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 15) {
                Button {
                    if let quiz = quizFetcher.value {
                        self.presentedQuiz = quiz
                    }
                } label: {
                    Label("Start Test", systemImage: "document")
                }
                .buttonStyle(.primaryAction)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .fetchOverlay(
            isFetching: quizFetcher.isFetching,
            fetchError: quizFetcher.error,
            retry: {
                fetchQuiz(delay: true)
            }
        )
        .nonProdEnvWarningOverlay()
        .floatingTabBarSafeAreaInset()
    }
    
    private func fetchQuiz(delay: Bool = false) {
        quizFetcher.fetch(delay: delay) {
            try await api.quiz()
        }
    }
}

#Preview {
    QuizAppView()
        .previewEnvironment()
}
