import Foundation

public struct ServerErrorPayload: Decodable {
    public var code: String?
    public var message: String
    public var stack: String
}
