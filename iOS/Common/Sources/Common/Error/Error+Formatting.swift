import Foundation

public func formatError(_ error: Error) -> String {
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
        return "Type mismatch, expecting \(expectedType) at path \(path)"

    case .valueNotFound(let expectedType, let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Value not found, expecting value of type \(expectedType) at path: \(path)"

    case .keyNotFound(let missingKey, let context):
        let path = formatCodingPath(from: context.codingPath)
        return "Expecting key '\(missingKey.stringValue)' at path \(path)"
        
    case .dataCorrupted(let context):
        // debugDescription contains more detailed info
        // However there seems to be not a way to extract it...
        let path = formatCodingPath(from: context.codingPath)
        return "Data corrupted at path \(path)"

    @unknown default:
        return error.localizedDescription
    }
}

/// Example: ["user", "address", 0, "city"] -> "user.address[0].city"
func formatCodingPath(from codingPath: [CodingKey]) -> String {
    var result = "(Root)"
    
    for codingKey in codingPath {
        result.append(" → ")
        
        if let intValue = codingKey.intValue {
            result.append("Index \(intValue)")
            
        } else {
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
    
    return "\(HTTPClient.formatStatusCode(statusCode)): \(payload.message)"
}
