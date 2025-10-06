import Foundation

extension DuckAuth {
    static let shared = DuckAuth(
        serverURL: {
            switch Target.current {
            case .prod: fatalError()
            case .local: URL(string: "http://192.168.0.207:7001")!
            }
        }(),
        clientID: "inventory-4L0YDPinr7U772eNb7Wy6Vim",
        clientSecret: "Ly2uULf6zVh75LjxNpnm6nnu"
    )
}
