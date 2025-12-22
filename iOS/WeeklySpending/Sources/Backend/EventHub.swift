import Foundation
import Combine
import Common
import Backend_deprecated
@preconcurrency import SocketIO

extension EventHub {
    static let shared = EventHub(baseURL: API.shared.baseURL)
    
    var templatesChangeEvents: AsyncStream<Void> {
        events("ws-app:templates:changed")
    }
    
    func userReportsChangeEvents(userID: String) -> AsyncStream<Void> {
        events("ws-app:user:\(userID):reports:changed")
    }
}
