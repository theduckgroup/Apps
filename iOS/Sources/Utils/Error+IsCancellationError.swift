import Foundation

extension Error {
    var isCancellationError: Bool {
        if self is CancellationError {
            return true
        }
        
        if self._domain == NSURLErrorDomain && self._code == NSURLErrorCancelled {
            return true
        }
        
        return false
    }
}
