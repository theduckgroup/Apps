public import Foundation
public import Supabase
import Common

@Observable
public final class Auth: @unchecked Sendable {
    private let impl: AuthImplProtocol
    
    init(impl: AuthImplProtocol) {
        self.impl = impl
    }
    
    convenience public init() {
        self.init(impl: AuthImpl())
    }
    
    public var isLoaded: Bool {
        impl.isLoaded
    }
    
    public var user: User? {
        impl.user
    }
    
    public var accessToken: String {
        get async throws {
            try await impl.accessToken
        }
    }
    
    public func signIn(email: String, password: String) async throws {
        try await impl.signIn(email: email, password: password)
    }
    
    public func signOut() async throws {
        try await impl.signOut()
    }
    
    public func handle(_ url: URL) {
        impl.handle(url)
    }
}

protocol AuthImplProtocol {
    init()
    
    var isLoaded: Bool { get }
    var user: User? { get }
    var accessToken: String { get async throws }
    
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    
    func handle(_ url: URL)
}

@Observable
private final class AuthImpl: AuthImplProtocol, @unchecked Sendable {
    // Probably need lock around isLoaded? Who cares
    
    public private(set) var isLoaded = false
    private var session: Session?
    private let supabase = SupabaseClient(supabaseURL: URL(string: "https://ahvebevkycanekqtnthy.supabase.co")!, supabaseKey: "sb_publishable_RYskGh0Y71aGJoncWRLZDQ_rp9Z0U2u")
    
    init() {
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
    
    var user: User? {
        session?.user
    }
    
    var accessToken: String {
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
    
    public func handle(_ url: URL) {
        supabase.auth.handle(url)
    }
}
