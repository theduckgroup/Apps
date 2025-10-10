import Foundation

struct GenericError: LocalizedError {
    var errorDescription: String?
    
    init(_ message: String) {
        self.errorDescription = message
    }
    
    public var debugDescription: String {
        "\(Self.self)(\"\(errorDescription!)\")"
    }
}
