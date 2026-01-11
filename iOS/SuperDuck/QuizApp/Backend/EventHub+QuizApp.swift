import Foundation

extension EventHub {
    var quizzesChanged: AsyncStream<Void> {
        events("quiz-app:quizzes:changed")
    }
}
