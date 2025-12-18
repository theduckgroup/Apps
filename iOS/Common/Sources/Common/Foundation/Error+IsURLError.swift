import Foundation

public extension Error {
    var isURLError: Bool {
        _domain == URLError.errorDomain
    }
}
