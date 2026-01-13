import Foundation
import Supabase
import Common

/*
 Test cases:
 1. Signing in/out
 2. Signing out from other device should not kick user out
 3. Changing password etc should kick user out
 4. Should not kick user out when unable to refresh tokens due to network errors
 5. Same as (4) but after launching the app
 */

@MainActor @Observable
final class Auth: @unchecked Sendable {
    private let impl: AuthImplProtocol
    
    init(impl: AuthImplProtocol) {
        self.impl = impl
    }
    
    convenience init() {
        self.init(impl: AuthImpl())
    }
    
    var isLoaded: Bool {
        impl.isLoaded
    }
    
    var user: User? {
        impl.user
    }
    
    var accessToken: String {
        get async throws {
            try await impl.accessToken
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await impl.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await impl.signOut()
    }
    
    func handle(_ url: URL) {
        impl.handle(url)
    }
}

@MainActor
protocol AuthImplProtocol {
    init()
    
    var isLoaded: Bool { get }
    var user: User? { get }
    var accessToken: String { get async throws }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    
    func handle(_ url: URL)
}

@MainActor @Observable
private final class AuthImpl: AuthImplProtocol {
    // Probably need lock around isLoaded? Who cares
    
    private(set) var isLoaded = false
    private var session: Session?
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://ahvebevkycanekqtnthy.supabase.co")!,
        supabaseKey: "sb_publishable_RYskGh0Y71aGJoncWRLZDQ_rp9Z0U2u",
        options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
    )
    
    init() {
        Task {
            // It's important that this is run on main thread since we're modifying properties observed by UI            
            MainActor.assertIsolated()
            
            for await (event, session) in supabase.auth.authStateChanges {
                logger.info("Received auth event \(event.rawValue), session = \(session != nil ? "not nil" : "nil")")
                // logger.info("Received auth event \(event.rawValue), session = \(session, default: "nil")")
                
                self.isLoaded = true
                self.session = session
                
                // Don't need this, kept for historical reason
                /*
                switch event {
                case .initialSession:
                    // In this case (app launch), if the tokens have expired, Supabase will try to
                    // refresh the tokens. If the attempt fails due to network error, `session` will
                    // be nil.
                    // `supabase.auth.currentSession` still holds a session (albeit with invalid JWT)
                    // We fallback to `supabase.auth.currentSession` because we don't want to keep
                    // user signed in until network comes back.
                    // Must re-assign the session for Observable to work
                    self.session = session ?? supabase.auth.currentSession
                    break
                    
                default:
                    self.session = session
                }
                */
            }
        }
    }
    
    var user: User? {
        session?.user
    }
    
    var accessToken: String {
        get async throws {
            try await supabase.auth.session.accessToken
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
        
        // Supabase needs a bit of time to send auth event
        try await Task.sleep(for: .seconds(0.5))
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut(scope: .local)
    }
    
    func handle(_ url: URL) {
         supabase.auth.handle(url)
    }
}
