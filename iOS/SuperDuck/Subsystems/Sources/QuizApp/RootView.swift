import Foundation
public import SwiftUI
import AppShared
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
    @Environment(API.self) var api
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                bodyContent()
            }
            .safeAreaInset(edge: .bottom) {
                loadingView()
            }
            .navigationTitle("FOH Test")
        }
        .fullScreenCover(item: $presentedQuiz) { quiz in
            QuizResponseView(quiz: quiz)
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
        VStack(alignment: .leading, spacing: 15) {
            Button {
                if let quiz {
                    self.presentedQuiz = quiz
                }
            } label: {
                Text("Start \(persistedQuizName.ifEmpty("Test"))")
                    .padding(.horizontal, 9)
            }
            .buttonStyle(.paperProminent)
            .disabled(quiz == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        if isFetching {
            HStack {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
                
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(.regularMaterial)
            }
            .padding(.bottom, 24)
            
        } else if let error {
            VStack(alignment: .leading) {
                Text(formatError(error))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Retry") {
                    fetchQuiz(delay: true)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .fixedSize(horizontal: false, vertical: false)
            .padding()
            .frame(width: horizontalSizeClass == .regular ? 570 : nil)
            .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemFill))
            }
            .padding()
        }
    }
    
    private func fetchQuiz(delay: Bool = false) {
        fetchTask?.cancel()
        
        fetchTask = Task {
            do {
                self.isFetching = true
                self.error = nil
                
                if debugging {
                    try await Task.sleep(for: .seconds(2))
                }
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                let fetchedQuiz = try await {
                    if isRunningForPreviews {
                        return try await api.mockQuiz()
                    }
                    
                    return try await api.quiz(code: "FOH_STAFF_KNOWLEDGE")
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
        .prepareForPreview()
}
