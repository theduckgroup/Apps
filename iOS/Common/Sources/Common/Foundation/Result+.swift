import Foundation

public extension Result {
    var isSuccess: Bool {
        switch self {
        case .success(_): true
        default: false
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .failure(_): true
        default: false
        }
    }

    /// Value if success or `nil` if failure.
    var value: Success? {
        switch self {
        case .success(let value): value
        case .failure: nil
        }
    }
}
