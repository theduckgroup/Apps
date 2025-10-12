import Foundation
import Supabase

@Observable
class Auth {
    static let shared = Auth()
    
    private var session: Session?
    private(set) var isLoaded = false
    private let supabaseClient = SupabaseClient(supabaseURL: URL(string: "https://ahvebevkycanekqtnthy.supabase.co")!, supabaseKey: "sb_publishable_RYskGh0Y71aGJoncWRLZDQ_rp9Z0U2u")
    
    private init() {
        Task {
            for await (event, session) in supabaseClient.auth.authStateChanges {
                logger.info("Receive auth event \(event.rawValue)")
                self.session = session
                self.isLoaded = true
            }
        }
    }
    
    var user: User? {
        if isRunningForPreviews {
            return User(
                id: UUID(),
                appMetadata: [:],
                userMetadata: [
                    "first_name": "The Duck Group App",
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
    
    var accessToken: String? {
        session?.accessToken
    }
    
    func signIn(email: String, password: String) async throws {
        try await supabaseClient.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await supabaseClient.auth.signOut(scope: .local)
    }
    
    func handleOAuthURL(_ url: URL) {
        supabaseClient.auth.handle(url)
    }
    
    func authorize(_ request: URLRequest) throws -> URLRequest {
        var request = request
        
        guard let session else {
            throw GenericError("User is not signed in")
        }
        
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}

extension User {
    var firstName: String {
        userMetadata["first_name"]?.value as? String ?? ""
    }
    
    var lastName: String {
        userMetadata["last_name"]?.value as? String ?? ""
    }
    
    var name: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
