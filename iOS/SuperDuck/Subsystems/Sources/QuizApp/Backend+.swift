import Foundation
import AppShared
import Backend
import Common

///// Server API.
//extension API {
//    static let shared = API(
//        auth: .shared,
//        baseURL: {
//            switch AppInfo.buildTarget {
//            case .prod: URL(string: "https://apps.theduckgroup.com.au/api/quiz-app")!
//            // case .local: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
//            case .local: URL(string: "http://172.20.10.11:8021/api/quiz-app")!
//            }
//        }()
//    )
//}

extension API {
    func quiz(code: String) async throws -> Quiz {
        try await get(
            path: "quiz-app/quiz",
            queryItems: [.init(name: "code", value: code)],
            decodeAs: Quiz.self
        )
    }
    
    func mockQuiz() async throws -> Quiz {
        try await get(
            authenticated: false,
            path: "quiz-app/mock-quiz",
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

extension EventHub {
    // static let shared = EventHub(baseURL: API.shared.baseURL)
    
    var quizzesChanged: AsyncStream<Void> {
        events("quiz-app:quizzes:changed")
    }
}
