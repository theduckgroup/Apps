import Foundation

class InventoryServer {
    static var url: URL {
        switch Target.current {
        case .prod: fatalError()
        case .local: URL(string: "http://192.168.0.207:7021")!
        }
    }
    
    static func makeRequest(httpMethod: String, path: String) async throws -> URLRequest {
        var request = URLRequest(url: url.appending(path: path))
        request.httpMethod = httpMethod
        
        let tokens = try await DuckAuth.shared.tokens()
        
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("mobile", forHTTPHeaderField: "Client-Type")
       
        return request
    }
}
