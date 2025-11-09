import Foundation
import Common
import Backend

/// Server API.
extension API {
    static let shared = API(
        auth: .shared,
        baseURL: {
            switch AppInfo.buildTarget {
            case .prod: URL(string: "https://apps.theduckgroup.com.au/api/quiz-app")!
            case .local: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
            }
        }()
    )
}

extension API {
    func quiz(code: String) async throws -> Quiz {
        try await get(
            path: "/quiz",
            queryItems: [.init(name: "code", value: code)],
            decodeAs: Quiz.self
        )
    }
    
    func mockQuiz() async throws -> Quiz {
        try await get(authenticated: false, path: "/mock-quiz", decodeAs: Quiz.self)
    }
    
    func submitQuizResponse(_ quizResponse: QuizResponse) async throws {
        try await post(method: "POST", path: "/quiz-response/submit", body: quizResponse)
    }
}
