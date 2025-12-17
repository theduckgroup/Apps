import Foundation
import Combine
import Common
import Backend
@preconcurrency import SocketIO

extension EventHub {
    static let shared = EventHub(baseURL: API.shared.baseURL)
    
    func templatesChanged() -> AsyncStream<Void> {
        print("Creating templates changed stream")
        return events("ws-app:templates:changed")
    }
    
    func userReportsChanged(userID: String) -> AsyncStream<Void> {
        events("ws-app:user:\(userID):reports:changed")
    }
}
