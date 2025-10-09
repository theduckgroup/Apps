import Foundation
import Supabase

class Server {
    static var url: URL {
        switch Target.current {
        case .prod: fatalError()
        case .local: URL(string: "http://192.168.0.207:8021")!
        }
    }
    
    static func makeRequest(httpMethod: String, path: String) throws -> URLRequest {
        var request = URLRequest(url: url.appending(path: path))
        request.httpMethod = httpMethod
        
        guard let accessToken = Auth.shared.accessToken else {
            throw GenericError("User is not signed in")
        }
        
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
}
