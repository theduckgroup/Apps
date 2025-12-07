import Foundation
import Combine
import Common
import Backend
@preconcurrency import SocketIO

extension EventHub {
    static let shared = EventHub(baseURL: API.shared.baseURL)
    
    func quizzesChanged() -> AsyncStream<Void> {
        print("Creating quizzes changed stream")
        return events("quiz-app:quizzes:changed")
    }
}
