import Foundation

public extension API {
    /// Mock API for previews.
    ///
    /// This uses local backend.
    @MainActor
    static let mock = API(env: .local, auth: .mock)
}
