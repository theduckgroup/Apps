import Foundation
import Backend

extension API {
    func quiz(code: String) async throws -> Quiz {
        try await get(
            path: "quiz-app/quiz",
            queryItems: [.init(name: "code", value: code)],
            decodeAs: Quiz.self
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
