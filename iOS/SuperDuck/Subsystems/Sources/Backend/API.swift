public import Foundation
import Supabase
import Common

@Observable
public final class API: Sendable {
    public let url: URL
    public let auth: Auth
    public let eventHub: EventHub
    
    public init(url: URL, auth: Auth) {
        self.auth = auth
        self.url = url
        self.eventHub = .init(url: url)
    }
    
    public func get<T: Decodable>(
        authenticated: Bool = true,
        path: String,
        queryItems: [URLQueryItem] = [],
        decodeAs type: T.Type = T.self
    ) async throws -> T {
        try await handle401 {
            let request = try await makeRequest(authenticated: authenticated, method: "GET", path: path, queryItems: queryItems)
            let data = try await HTTPClient().get(request, decodeAs: type)
            return data
        }
    }
    
    public func post<T: Encodable>(
        authenticated: Bool = true,
        method: String,
        path: String,
        body: T
    ) async throws {
        try await handle401 {
            var request = try await makeRequest(authenticated: authenticated, method: method, path: path, queryItems: [])

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
            
            _ = try await HTTPClient().post(request, json: true)
        }
    }
    
    private func makeRequest(authenticated: Bool, method: String, path: String, queryItems: [URLQueryItem]) async throws -> URLRequest {
        var url = url.appending(path: path)
        
        if queryItems.count > 0 {
            url.append(queryItems: queryItems)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if authenticated {
            let accessToken = try await auth.accessToken
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func handle401<T, E>(_ block: () async throws(E) -> T) async throws(E) -> T {
        do {
            return try await block()
            
        } catch {
            if let error = error as? HTTPClient.BadStatusCodeError, error.response.statusCode == 401 {
                logger.info("Request failed with 401 status, signing out")
                try? await auth.signOut()
            }
        
            throw error
        }
    }
}
