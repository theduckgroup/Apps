import Foundation
import SwiftUI

struct HomeView: View {
    @AppStorage("App:persistedQuizName") var persistedQuizName: String = ""
    @State var quizResult: Result<Quiz, Error>?
    @State var error: Error?
    @State var isFetching = false
    @State var fetchTask: Task<Void, Never>?
    @State var presentedQuiz: Quiz?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        bodyContent()
            .fullScreenCover(item: $presentedQuiz) { quiz in
                QuizView(quiz: quiz)
            }
            .onAppear {
                fetchQuiz()
            }
            .onReceive(EventHub.shared.quizzesChanged) {
                fetchQuiz()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    fetchQuiz()
                }
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ZStack {
            VStack(spacing: 15) {
                if !persistedQuizName.isEmpty {
                    Text(persistedQuizName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                let quiz: Quiz? = if let quizResult, case .success(let quiz) = quizResult {
                    quiz
                } else {
                    nil
                }
                
                Button {
                    if let quiz {
                        self.presentedQuiz = quiz
                    }
                } label: {
                    Text("Start")
                        .font(.title2)
                        .padding(.horizontal)
                }
                .disabled(quiz == nil)
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if isFetching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 30)
                
            } else if let quizResult, case .failure(let error) = quizResult {
                VStack(alignment: .trailing) {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                    
                    Button("Retry") {
                        fetchQuiz()
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.quaternarySystemFill))
                }
                .padding()
                
            }
        }
    }
    
    private func fetchQuiz() {
        fetchTask?.cancel()
        
        fetchTask = Task {
            isFetching = true
            
            do {
                try await Task.sleep(for: .seconds(0.5)) // Grace
                
                let quiz = try await {
                    if isRunningForPreviews {
                        return try await Server.mockQuiz()
                    }
                    
                    return try await Server.quiz(code: "FOH_STAFF_KNOWLEDGE")
                }()

                self.quizResult = .success(quiz)
                self.persistedQuizName = quiz.name
                
                isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                isFetching = false
                
                logger.error("Unable to parse quiz: \(error)")
                self.quizResult = .failure(error)
            }
        }
    }
}

extension View {
    @ViewBuilder
    func onReceive<T>(_ stream: AsyncStream<T>, assignTo: Binding<T>) -> some View {
        task {
            for await value in stream {
                assignTo.wrappedValue = value
            }
        }
    }
    
    @ViewBuilder
    func onReceive<T>(_ createStream: @escaping () -> AsyncStream<T>, perform: @escaping (T) -> Void) -> some View {
        task {
            print("Creating task")
            
            for await value in createStream() {
                perform(value)
            }
        }
    }
}

#Preview {
    HomeView()
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: true
        case .failure: false
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .success: false
        case .failure: true
        }
    }
    
    var error: Error? {
        switch self {
        case .success: nil
        case .failure(let error): error
        }
    }
}
