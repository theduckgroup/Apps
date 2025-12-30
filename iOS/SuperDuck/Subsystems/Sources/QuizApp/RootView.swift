import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct RootView: View {
    @State var quiz: Quiz?
    @AppStorage("App:persistedQuizName") var persistedQuizName: String = ""
    @State var error: Error?
    @State var isFetching = false
    @State var fetchTask: Task<Void, Never>?
    @State var presentedQuiz: Quiz?
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(AppDefaults.self) var appDefaults
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
        .onAppear {
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
                    if let quiz {
                        self.presentedQuiz = quiz
                    }
                } label: {
                    Text("Start \(persistedQuizName.ifEmpty("Test"))")
                }
                .buttonStyle(.primaryAction)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .fetchOverlay(
            isFetching: isFetching,
            fetchError: error,
            retry: {
                fetchQuiz(delay: true)
            }
        )
        .nonProdEnvWarningOverlay()
    }
    
    private func fetchQuiz(delay: Bool = false) {
        fetchTask?.cancel()
        
        fetchTask = Task {
            do {
                self.error = nil
                self.isFetching = true
                
                // Can't set isFetching in defer due to cancellation
                
                if delay {
                    try await Task.sleep(for: .seconds(0.5))
                }
                
                if debugging {
                    // try await Task.sleep(for: .seconds(2))
                    // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                    // throw GenericError("Not connected to internet")
                }
                
                let fetchedQuiz = try await {
                    if isRunningForPreviews {
                        return try await api.mockQuiz(success: true)
                    }
                    
                    return try await api.quiz()
                }()

                self.quiz = fetchedQuiz
                self.persistedQuizName = fetchedQuiz.name
                self.isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                self.error = error
                self.isFetching = false
            }
        }
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
