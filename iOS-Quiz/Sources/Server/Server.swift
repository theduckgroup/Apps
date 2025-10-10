import Foundation
import Supabase

class Server {
    static var apiURL: URL {
        switch Target.current {
        case .prod: fatalError()
        case .local: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
        }
    }
    
    static func quiz(code: String) async throws -> Quiz {
        var request = try makeRequest(httpMethod: "GET", path: "quiz")
        request.url!.append(queryItems: [.init(name: "code", value: "FOH_STAFF_KNOWLEDGE")])
        
        let data = try await HTTPClient().get(request)
        let quiz = try JSONDecoder().decode(Quiz.self, from: data)
        return quiz
    }
    
    static func mockQuiz() async throws -> Quiz {
        let request = try makeRequest(authenticated: false, httpMethod: "GET", path: "mock-quiz")
        let data = try await HTTPClient().get(request)
        let quiz = try JSONDecoder().decode(Quiz.self, from: data)
        return quiz
    }
    
    static func makeRequest(authenticated: Bool = true, httpMethod: String, path: String) throws -> URLRequest {
        var request = URLRequest(url: apiURL.appending(path: path))
        request.httpMethod = httpMethod
        
        if authenticated {
            guard let accessToken = Auth.shared.accessToken else {
                throw GenericError("User is not signed in")
            }
            
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
