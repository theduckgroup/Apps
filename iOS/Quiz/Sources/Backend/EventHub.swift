import Foundation
import Combine
import Common
import Backend

extension EventHub {
    static let shared = EventHub(baseURL: API.shared.baseURL)
    
    var quizzesChanged: AsyncStream<Void> {
        events("quiz-app:quizzes:changed")
    }
}
