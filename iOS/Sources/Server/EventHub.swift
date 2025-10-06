import Foundation
import SocketIO
import Combine

class EventHub {
    static let shared = EventHub()
    
    private let socketManager = SocketManager(
        socketURL: InventoryServer.url,
        config: [
            .path("/socketio"), // url.append(path:) doesn't work
            .compress,
            // .log(true),
        ]
    )
    
    private init() {
        let socket = socketManager.defaultSocket
            
        socket.on(clientEvent: .connect) { data, ack in
            logger.info("! Socket connected")
        }
        
        socket.on("event") { data, ack in
            logger.info("! data = \(data)")
        }
        
        socket.connect()
    }
    
    func connected() -> some Publisher<Void, Never> {
        EventPublisher(socket: socketManager.defaultSocket, eventName: "connect")
            .map { _ in () }
    }
    
    // NOT TESTED
    func disconnected() -> some Publisher<Void, Never> {
        EventPublisher(socket: socketManager.defaultSocket, eventName: "disconnect")
            .map { _ in () }
    }
    
    func vendorChanged(vendorId: String) -> some Publisher<Void, Never> {
        let eventName = "event.vendor:\(vendorId).change"

        return EventPublisher(socket: socketManager.defaultSocket, eventName: eventName)
            .map { _ in () }
    }
    
    // Namespace implementation
    
    /*
    func vendorChanged(vendorId: String) -> EventPublisher {
        let client = socketManager.socket(forNamespace: "/vendor:\(vendorId)")
        return EventPublisher(client: client)
    }
    */
}

private struct EventPublisher: Publisher {
    typealias Output = [Any] // Socket.io data type
    typealias Failure = Never
    
    let socket: SocketIOClient
    let eventName: String

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        let subscription = EventSubscription(socket: socket, eventName: eventName, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private class EventSubscription<S: Subscriber>: Subscription where S.Input == Array<Any>, S.Failure == Never {
    let socket: SocketIOClient
    let handlerID: UUID
    private var subscriber: S?
    
    init(
        socket: SocketIOClient,
        eventName: String,
        subscriber: S
    ) {
        self.socket = socket
        self.subscriber = subscriber
        
        self.handlerID = socket.on(eventName) { data, ack in
            logger.info("Received \(eventName), data = \(data)")
            _ = subscriber.receive(data)
        }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        subscriber = nil // Stop sending events
        socket.off(id: handlerID)
    }
}

// Namespace implementation

/*
class EventPublisher {
    let client: SocketIOClient
    
    fileprivate init(client: SocketIOClient) {
        self.client = client

        client.connect()
    }
    
    deinit {
        client.disconnect()
    }
    
    func sink(_ handler: @escaping () -> Void) {
        client.on("change") { data, ack in
            handler()
        }
    }
}
*/
