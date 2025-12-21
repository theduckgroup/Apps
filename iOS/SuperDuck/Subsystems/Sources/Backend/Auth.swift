public import Foundation
public import Supabase
import Common

// TODO: Remove @MainActor & shared
@MainActor @Observable
final public class Auth {
    public static let shared = Auth()
    
    public private(set) var isLoaded = false
    private var session: Session?
    private let supabase = SupabaseClient(supabaseURL: URL(string: "https://ahvebevkycanekqtnthy.supabase.co")!, supabaseKey: "sb_publishable_RYskGh0Y71aGJoncWRLZDQ_rp9Z0U2u")
    
    private init() {
        Task {
            for await (_, session) in supabase.auth.authStateChanges {
                // logger.info("Received auth event \(event.rawValue), session = \(session, default: "")")
                
                // Fallback to supabase.auth.currentSession because in case of network issue, Supabase
                // may fail to obtain access token and we only receive an INITIAL_SESSION event with a nil session
                // However supabase.auth.currentSession still holds a session (albeit with invalid JWT)
                // (Setting session to nil will cause UI to display Login screen)
                // Must assign session to a property for observable to work
                self.session = session ?? supabase.auth.currentSession
                
                self.isLoaded = true
            }
        }
    }
    
    public var user: User? {
        if isRunningForPreviews {
            return User(
                id: UUID(),
                appMetadata: [:],
                userMetadata: [
                    "first_name": "Mock User",
                    "last_name": ""
                ],
                aud: "",
                email: "theduckgroupapp@gmail.com",
                createdAt: Date(),
                updatedAt: Date(),
            )
        }
        
        return session?.user
    }
    
    public var accessToken: String {
        get async throws {
            try await supabase.auth.session.accessToken
        }
    }
    
    public func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
        
        // Supabase needs a bit of time to send auth event
        try await Task.sleep(for: .seconds(0.5))
    }
    
    public func signOut() async throws {
        try await supabase.auth.signOut(scope: .local)
    }
    
    public func handleOAuthURL(_ url: URL) {
        supabase.auth.handle(url)
    }
}

extension User {
    public var firstName: String {
        userMetadata["first_name"]?.value as? String ?? ""
    }
    
    public var lastName: String {
        userMetadata["last_name"]?.value as? String ?? ""
    }
    
    public var name: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
