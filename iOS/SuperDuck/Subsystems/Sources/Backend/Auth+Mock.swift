import Foundation

public extension Auth {
    /// Mock `Auth` that always returns mock user.
    static let mock = Auth(impl: AuthMockImpl())
}

private final class AuthMockImpl: AuthImplProtocol {
    var isLoaded: Bool {
        true
    }
    
    var user: User? {
        .mock
    }
    
    var accessToken: String {
        get async throws {
            "accessToken"
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Task.sleep(for: .seconds(2))
    }
    
    func signOut() async throws {
        try await Task.sleep(for: .seconds(2))
    }
    
    func handle(_ url: URL) {
        fatalError()
    }
}
