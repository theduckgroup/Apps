import Foundation

struct GenericError: Error {
    var localizedDescription: String?
    
    init(_ message: String) {
        self.localizedDescription = message
    }
}
