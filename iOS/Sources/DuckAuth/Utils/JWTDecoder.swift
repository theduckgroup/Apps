import Foundation

struct JWTDecoder {
    /// Decodes the payload of a JWT string into a dictionary.
    static func decode(_ jwtString: String) throws -> [String: Any] {
        let segments = jwtString.components(separatedBy: ".")
        
        guard segments.count == 3 else {
            throw JWTDecodingError.invalidTokenFormat
        }
        
        let payloadSegment = segments[1]
        
        guard let payloadData = base64UrlDecode(payloadSegment) else {
            throw JWTDecodingError.base64DecodingFailed
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: payloadData, options: [])
        
        guard let payload = jsonObject as? [String: Any] else {
            throw JWTDecodingError.invalidJSONStructure
        }
        
        return payload
    }
    
    /// Decodes the payload of a JWT string into a specific `Codable` type.
    static func decode<T: Decodable>(_ jwtString: String, as type: T.Type) throws -> T {
        let segments = jwtString.components(separatedBy: ".")
        
        guard segments.count == 3 else {
            throw JWTDecodingError.invalidTokenFormat
        }
        
        let payloadSegment = segments[1]
        
        guard let payloadData = base64UrlDecode(payloadSegment) else {
            throw JWTDecodingError.base64DecodingFailed
        }
        
        // Consider setting dateDecodingStrategy if your JWT uses date claims (like 'exp', 'iat')
        // decoder.dateDecodingStrategy = .secondsSince1970 // Common format
        
        return try JSONDecoder().decode(T.self, from: payloadData)
    }
        
    private static func base64UrlDecode(_ base64Url: String) -> Data? {
        // JWT uses Base64Url, which is slightly different from standard Base64
        // It replaces + with - and / with _, and omits padding (=)

        var base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if necessary (Base64 requires padding to be a multiple of 4)
        
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        // Use Data's standard Base64 decoder, ignoring potential unknown characters
        // (after replacement and padding, it should be clean)
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
}

enum JWTDecodingError: Error {
    /// Token doesn't have 3 parts (header.payload.signature)
    case invalidTokenFormat
    
    /// Failed to decode the payload from Base64Url
    case base64DecodingFailed
    
    /// Failed to parse the decoded data as JSON
    case jsonDecodingFailed(Error)
    
    /// Decoded JSON is not a dictionary or expected structure
    case invalidJSONStructure
}
