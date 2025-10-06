import Foundation
import UIKit

@Observable
class UserManager {
    /// Shared instance.
    static let shared = {
        if isRunningForPreviews {
            return UserManager(mockUser: .mock)
        }
        
        return UserManager()
    }()
    
    /// Current user.
    private(set) var user: User?
    
    private let mockUser: User?
    private let userStorageKey = "user"
    private let userDefaults = UserDefaults.standard
    private let auth = DuckAuth.shared
    
    private init() {
        if let userData = UserDefaults.standard.data(forKey: userStorageKey) {
            do {
                self.user = try JSONDecoder().decode(User.self, from: userData)
                logger.info("User restored")
                
            } catch {
                logger.error("Unable to decode user data: \(error)")
            }
        }
        
        mockUser = nil
        
        auth.onRefreshTokensNonRecoverableError = {
            Task {
                await self.logout()
            }
        }
    }
    
    private init(mockUser: User?) {
        self.mockUser = mockUser
        self.user = mockUser
    }
    
    private var mock: Bool {
        mockUser != nil
    }
    
    func login(username: String, password: String) async throws {
        try await auth.login(username: username, password: password)
        try await refreshUser()
    }
    
    func logout() {
        userDefaults.removeObject(forKey: userStorageKey)
        self.user = nil
        
        Task {
            // User is logged out even if this fails
            try await auth.logout()
        }
    }
    
    /// Refreshes user.
    func refreshUser() async throws {
        if mock {
            return
        }

        let request = try await InventoryServer.makeRequest(httpMethod: "GET", path: "/auth/user")
        
        let user = try await HTTPClient.shared.get(request, decodeAs: User.self)
        
        userDefaults.set(try! JSONEncoder().encode(user), forKey: userStorageKey)

        self.user = user
    }
    
    func resetData() {
        userDefaults.removeObject(forKey: userStorageKey)
        auth.resetData()
        self.user = nil
    }
}
