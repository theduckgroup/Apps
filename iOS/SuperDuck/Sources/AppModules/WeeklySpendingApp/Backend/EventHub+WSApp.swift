import Foundation

extension EventHub {
    var templatesChangeEvents: AsyncStream<Void> {
        events("ws-app:templates:changed")
    }
    
    func userReportsChangeEvents(userID: String) -> AsyncStream<Void> {
        events("ws-app:user:\(userID):reports:changed")
    }
}
