import Foundation

func formatError(_ error: Error) -> String {
    if let error = error as? DecodingError {
        formatDecodingError(error)
        
    } else if let error = error as? HTTPClient.BadStatusCodeError {
        formatBadStatusCodeError(error)
        
    } else {
        error.localizedDescription
    }
}

// Decoding error

private func formatDecodingError(_ error: DecodingError) -> String {
    switch error {
    case .typeMismatch(let expectedType, let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Type mismatch: expected \(expectedType) at path: \(path)"

    case .valueNotFound(let expectedType, let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Value not found: expected value of type \(expectedType) at path: \(path)"

    case .keyNotFound(let missingKey, let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Key '\(missingKey.stringValue)' not found at path: \(path)"
        
    case .dataCorrupted(let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Data corrupted at path \(path)."

    @unknown default:
        return error.localizedDescription
    }
}

/// Example: ["user", "address", 0, "city"] -> "user.address[0].city"
func formatCodingPath(from codingPath: [CodingKey]) -> String {
    guard !codingPath.isEmpty else {
        return "(Root)"
    }
    
    var result = ""
    
    for (index, codingKey) in codingPath.enumerated() {
        if let intValue = codingKey.intValue {
            result.append("[\(intValue)]")
            
        } else {
            if index > 0 {
                result.append(".")
            }
            
            result.append(codingKey.stringValue)
        }
    }
    
    return result
}

// Bad status code error

private func formatBadStatusCodeError(_ error: HTTPClient.BadStatusCodeError) -> String {
    let statusCode = error.response.statusCode
    let data = error.data
    
    // Parse the data based on agreed-upon server response
    
    guard let payload = try? JSONDecoder().decode(ServerErrorPayload.self, from: error.data) else {
        assertionFailure()
        return String(data: data, encoding: .utf8)!
    }
    
    if payload.code == "INVALID_CREDENTIALS" {
        return "Incorrect username or password"
        
    } else {
        return "\(HTTPClient.formatStatusCode(statusCode)): \(payload.message)"
    }
}

private struct ServerErrorPayload: Decodable {
    var code: String?
    var message: String
    var stack: String
}
