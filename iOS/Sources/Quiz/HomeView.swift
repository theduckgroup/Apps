import Foundation
import SwiftUI

struct HomeView: View {
    @State var quiz: Result<Quiz, Error>?
    @State var presentedQuiz: Quiz?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        bodyContent()
            .fullScreenCover(item: $presentedQuiz) { quiz in
                QuizView(quiz: quiz)
            }
            .onReceive(EventHub.shared.quizzesChanged) {
                fetchQuizDesign()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    fetchQuizDesign()
                }
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ZStack {
            Button("Start") {
                guard case .success(let quiz) = quiz else {
                    return
                }
                
                self.presentedQuiz = quiz
            }
            .disabled(quiz == nil || quiz!.isFailure)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if case .failure(let error) = quiz {
                VStack {
                    Text("Unable to load data: \(error.localizedDescription)")
                        .foregroundStyle(.red)
                    
                    Button("Retry") {
                        fetchQuizDesign()
                    }
                }
                .padding()
                .foregroundStyle(.white)
                .background(Color.yellow)
            }
        }
    }
    
    private func fetchQuizDesign() {
        Task {
            if let quiz, quiz.isFailure {
                self.quiz = nil
            }
            
            do {
                let request = try Server.makeRequest(httpMethod: "GET", path: "/api/quiz/code/FOH_STAFF_KNOWLEDGE")
                let data = try await HTTPClient().get(request)
                let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                self.quiz = .success(quiz)
                
            } catch {
                logger.error("Unable to parse quiz: \(error)")
                self.quiz = .failure(error)
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
        .preferredColorScheme(.dark)
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
}
