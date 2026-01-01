import Foundation

public extension API {
    /// Mock API for previews.
    ///
    /// This uses local backend.
    @MainActor
    static let localWithMockAuth = API(env: .local, auth: .mock)
}
