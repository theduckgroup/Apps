import Foundation

public struct GenericError: LocalizedError {
    public var errorDescription: String?
    
    public init(_ message: String) {
        self.errorDescription = message
    }
    
    public var debugDescription: String {
        "\(Self.self)(\"\(errorDescription!)\")"
    }
}
