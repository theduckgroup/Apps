import Foundation
import Supabase

/// Server API.
extension API {
    static let shared = API(
        auth: .shared,
        baseURL: {
            switch AppInfo.buildTarget {
            case .prod: fatalError()
            case .local: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
            }
        }()
    )
}

class API {
    let auth: Auth
    let baseURL: URL
    
    init(auth: Auth, baseURL: URL) {
        self.auth = auth
        self.baseURL = baseURL
    }
    
    func get<T: Decodable>(
        authenticated: Bool = true,
        path: String,
        queryItems: [URLQueryItem] = [],
        decodeAs type: T.Type
    ) async throws -> T {
        try await handle401 {
            let request = try await makeRequest(authenticated: authenticated, method: "GET", path: path, queryItems: queryItems)
            let data = try await HTTPClient().get(request)
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        }
    }
    
    func post<T: Encodable>(
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
        var url = baseURL.appending(path: path)
        
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

extension API {
    func quiz(code: String) async throws -> Quiz {
        try await get(
            path: "/quiz",
            queryItems: [.init(name: "code", value: "FOH_STAFF_KNOWLEDGE")],
            decodeAs: Quiz.self
        )
    }
    
    func mockQuiz() async throws -> Quiz {
        try await get(authenticated: false, path: "/mock-quiz", decodeAs: Quiz.self)
    }
    
    func submitQuizResponse(_ quizResponse: QuizResponse) async throws {
        try await post(method: "POST", path: "/quiz-response/submit", body: quizResponse)
    }
}
