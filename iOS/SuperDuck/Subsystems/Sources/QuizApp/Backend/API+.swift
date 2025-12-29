import Foundation
import Backend

extension API {
    func quiz() async throws -> Quiz {
        try await get(
            path: "quiz-app/quiz/68e5052313908f614bbab024"
        )
    }
    
    func mockQuiz(success: Bool = true) async throws -> Quiz {
        try await get(
            authenticated: false,
            path: success ? "quiz-app/mock-quiz" : "???",
            decodeAs: Quiz.self
        )
    }
    
    func submitQuizResponse(_ quizResponse: QuizResponse) async throws {
        try await post(
            method: "POST",
            path: "quiz-app/quiz-response/submit",
            body: quizResponse
        )
    }
}
