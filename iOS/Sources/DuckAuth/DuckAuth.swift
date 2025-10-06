import Foundation
import UIKit
import Combine

public class DuckAuth {
    public let serverURL: URL
    public let clientID: String
    public let clientSecret: String
    public var onRefreshTokensNonRecoverableError: () -> Void = {}
    private let refreshTokensDeduplicatePool = DeduplicatePool<(Tokens, Data)>()
    private let tokensStorageKey = "DuckAuth:tokens"
    
    public init(serverURL: URL, clientID: String, clientSecret: String) {
        self.serverURL = serverURL
        self.clientID = clientID
        self.clientSecret = clientSecret
    }
    
    /// Logs in.
    @MainActor
    func login(username: String, password: String) async throws {
        var request = URLRequest(httpMethod: "POST", baseURL: serverURL, path: "/auth/authorize")
        prepare(&request)
        
        let device = UIDevice.current
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: [
            "username": username,
            "password": password,
            "device": [
                "deviceType": "mobile",
                "deviceId": device.identifierForVendor!.uuidString.lowercased(),
                "model": device.modelCode,
                "os": "\(device.systemName) \(device.systemVersion)"
            ]
        ])
        
        let data = try await HTTPClient.shared.post(request, json: true)
        _ = try JSONDecoder().decode(Tokens.self, from: data) // Validate data
        
        Keychain.setValue(data, forKey: tokensStorageKey)
    }
    
    /// Logs out.
    @MainActor
    func logout() async throws {
        let tokens = try await storedTokens()
        
        Keychain.removeValueForKey(tokensStorageKey)
        
        var request = URLRequest(httpMethod: "POST", baseURL: serverURL, path: "/auth/token/revoke")
        prepare(&request)
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: [
            "refreshToken": tokens.refreshToken
        ])
        
        _ = try await HTTPClient.shared.post(request, json: true)
    }
    
    /// Gets tokens. Tokens are refreshed if needed.
    func tokens() async throws -> Tokens {
        // Read and decode tokens
        
        let tokens: Tokens
        
        do {
            tokens = try await storedTokens()
            
        } catch {
            onRefreshTokensNonRecoverableError()
            // assertionFailure()
            throw error
        }
        
        // Decode access token payload
        
        let atp: AccessTokenPayload
        
        do {
            atp = try JWTDecoder.decode(tokens.accessToken, as: AccessTokenPayload.self)
            
        } catch {
            onRefreshTokensNonRecoverableError()
            assertionFailure("Unable to decode access token: \(formatError(error))")
            throw GenericError("Unable to decode access token: \(error)")
        }
        
        // Handle expiration & refresh
        
        let exp = Date(timeIntervalSince1970: TimeInterval(atp.exp))
        let expiresIn = exp.timeIntervalSince(Date())
        
        let formatStyle = FloatingPointFormatStyle<Double>().precision(.fractionLength(1))
        logger.info("Access token expires in \(formatStyle.format(expiresIn)) secs")
        
        if expiresIn < 0 {
            do {
                let (tokens, data) = try await refreshTokensDeduplicatePool.run(key: "refreshTokens:\(tokens.refreshToken)") {
                    {
                        try await self.refreshTokenRequest(withRefreshToken: tokens.refreshToken)
                    }
                }
                
                Keychain.setValue(data, forKey: tokensStorageKey)
                
                return tokens
                
            } catch {
                // Log user out only for 401
                // This makes sure user is not kicked out because internet connectivity or temporary server issues
                
                let is401Error = (error as? HTTPClient.BadStatusCodeError)?.response.statusCode == 401
                // let isURLLoadingError = (error as NSError).domain == NSURLErrorDomain
                
                if is401Error {
                    logger.info("Refresh token failed with 401 error; log user out an rethrow")
                    onRefreshTokensNonRecoverableError()
                    throw error
                    
                } else {
                    logger.info("Refresh token failed: \(formatError(error))")
                    throw error
                }
            }
        }
        
        // Return stored tokens
        
        return tokens
    }
    
    private func storedTokens() async throws -> Tokens {
        // Read and decode tokens
        
        let tokens: Tokens
        
        do {
            guard let tokensData = Keychain.dataValueForKey(tokensStorageKey) else {
                onRefreshTokensNonRecoverableError()
                throw GenericError("Tokens not found in keychain")
            }
            
            tokens = try JSONDecoder().decode(Tokens.self, from: tokensData)
            
        } catch {
            onRefreshTokensNonRecoverableError()
            // assertionFailure()
            throw error
        }
        
        return tokens
    }
    
    private func refreshTokenRequest(withRefreshToken refreshToken: String) async throws -> (Tokens, Data) {
        var request = URLRequest(httpMethod: "POST", baseURL: serverURL, path: "/auth/token/refresh")
        prepare(&request)
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: [
            "refreshToken": refreshToken
        ])
        
        let data = try await HTTPClient.shared.post(request, json: true)
        let tokens = try JSONDecoder().decode(Tokens.self, from: data)
        
        return (tokens, data)
    }
        
    /// Prepares a request to auth server.
    private func prepare(_ request: inout URLRequest) {
        let authorization = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
    }

    /// Resets data.
    func resetData() {
        Keychain.removeValueForKey(tokensStorageKey)
    }
}

extension DuckAuth {
    struct Tokens: Codable {
        var accessToken: String
        var refreshToken: String
    }
    
    struct AccessTokenPayload: Codable {
        var userId: String
        var username: String
        var roles: [String]
        var exp: Int // The only thing that is used
        var iat: Int
        var aud: String?
    }
}
