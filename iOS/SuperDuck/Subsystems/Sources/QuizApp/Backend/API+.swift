import Foundation
import Backend
import Common

extension API {
    func quiz() async throws -> Quiz {
        if isRunningForPreviews {
            return try await get(authenticated: false, path: "quiz-app/mock-quiz")
        }
        
        return try await get( path: "quiz-app/quiz/68e5052313908f614bbab024")
    }
    
    func submitQuizResponse(_ quizResponse: QuizResponse) async throws {
        try await post(
            method: "POST",
            path: "quiz-app/quiz-response/submit",
            body: quizResponse
        )
    }
}
