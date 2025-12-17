import Foundation

nonisolated
public struct HTTPClient: Sendable {
    public static let shared = HTTPClient()
    
    private let urlSession = URLSession.shared
    
    public init() {}
    
    public func get(_ request: URLRequest) async throws -> Data {
        assert(request.httpBody == nil)
        
        var data1: Data?
        
        do {
            logRequest(request)
            
            let (data, response) = try await urlSession.data(for: request)
            data1 = data
            
            try validateResponse(response, data)

            logResponse(request, response, data)
            
            return data
            
        } catch {
            logError(request, error, data1)
            throw error
        }
    }
    
    public func get<T: Decodable>(_ request: URLRequest, decodeAs type: T.Type = T.self) async throws -> T {
        let data = try await get(request)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch {
            let message = "\(request.httpMethod!) \(request.url!) ~ Decoding Error: \(formatError(error))"
            logger.error(message)
            throw error
        }
    }
    
    public func post(_ request: URLRequest, json: Bool) async throws -> Data {
        precondition(request.httpBody != nil)
        
        var request = request
        
        if json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        var data1: Data?
        
        do {
            logRequest(request)
            
            let (data, response) = try await urlSession.data(for: request)
            data1 = data
            
            try validateResponse(response, data)

            logResponse(request, response, data)
            
            return data
            
        } catch {
            logError(request, error, data1)
            throw error
        }
    }
    
    private func validateResponse(_ response: URLResponse, _ data: Data) throws {
        let response = response as! HTTPURLResponse
        
        guard (200..<300).contains(response.statusCode) else {
            throw BadStatusCodeError(response: response, data: data)
        }
        
        return
    }
        
    private func logRequest(_ request: URLRequest) {
        var message = "\(request.httpMethod!) \(request.url!)"
        
        let headers = (request.allHTTPHeaderFields ?? [:])
            .sorted(using: KeyPathComparator(\.key.localizedLowercase))
            .map { "- \($0): \($1)" }
            .joined(separator: "\n")
        
        if !headers.isEmpty {
            message += "\n[Headers]\n\(headers)"
        }
        
        if let body = request.httpBody {
            message += "\n[Body (\(body.count) bytes)]\n\(formatData(body))"
        }
        
        message += "\n"
        
        logger.info(message)
    }
    
    private func logError(_ request: URLRequest, _ error: Error, _ data: Data? = nil) {
        var message = "\(request.httpMethod!) \(request.url!) ~ Error: \(error)"
        
        if let data {
            message += "\n[Data (\(data.count) bytes)]\n\(formatData(data))"
        }
        
        message += "\n"
        
        logger.info(message)
    }
    
    private func logResponse(_ request: URLRequest, _ response: URLResponse, _ data: Data) {
        let response = response as! HTTPURLResponse
        
        var message =
        """
        \(request.httpMethod!) \(request.url!) ~ \(Self.formatStatusCode(response.statusCode))
        [Data (\(data.count) bytes)]
        \(formatData(data))
        """
        
        message += "\n"
        
        logger.info(message)
    }
    
    private func formatData(_ data: Data) -> String {
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let prettyData = try! JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted])
            return String(data: prettyData, encoding: .utf8)!
                        
        } catch {
            if let string = String(data: data, encoding: .utf8) {
                return string
            }
            
            return "(Non-UTF8 data)"
        }
    }
}

extension HTTPClient {
    public struct BadStatusCodeError: LocalizedError {
        public let response: HTTPURLResponse
        public let data: Data
        
        public var errorDescription: String? {
            HTTPClient.formatStatusCode(response.statusCode)
        }
    }
}

extension HTTPClient {
    static func formatStatusCode(_ statusCode: Int) -> String {
        let text = httpStatusCodes[statusCode]!
        return "\(statusCode) \(text)"
    }
    
    static private let httpStatusCodes: [Int: String] = [
        // 1xx Informational
        100: "Continue",
        101: "Switching Protocols",
        102: "Processing", // WebDAV

        // 2xx Success
        200: "OK",
        201: "Created",
        202: "Accepted",
        203: "Non-Authoritative Information",
        204: "No Content",
        205: "Reset Content",
        206: "Partial Content",
        207: "Multi-Status", // WebDAV
        208: "Already Reported", // WebDAV
        226: "IM Used", // HTTP Delta encoding

        // 3xx Redirection
        300: "Multiple Choices",
        301: "Moved Permanently",
        302: "Found", // Previously "Moved Temporarily"
        303: "See Other",
        304: "Not Modified",
        305: "Use Proxy", // Deprecated
        307: "Temporary Redirect",
        308: "Permanent Redirect",

        // 4xx Client Error
        400: "Bad Request",
        401: "Unauthorized",
        402: "Payment Required",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        406: "Not Acceptable",
        407: "Proxy Authentication Required",
        408: "Request Timeout",
        409: "Conflict",
        410: "Gone",
        411: "Length Required",
        412: "Precondition Failed",
        413: "Payload Too Large", // Previously "Request Entity Too Large"
        414: "URI Too Long", // Previously "Request-URI Too Long"
        415: "Unsupported Media Type",
        416: "Range Not Satisfiable", // Previously "Requested Range Not Satisfiable"
        417: "Expectation Failed",
        418: "I'm a teapot", // RFC 2324, April Fools' joke
        421: "Misdirected Request",
        422: "Unprocessable Entity", // WebDAV
        423: "Locked", // WebDAV
        424: "Failed Dependency", // WebDAV
        425: "Too Early", // Experimental
        426: "Upgrade Required",
        428: "Precondition Required",
        429: "Too Many Requests",
        431: "Request Header Fields Too Large",
        451: "Unavailable For Legal Reasons", // Internet censorship

        // 5xx Server Error
        500: "Internal Server Error",
        501: "Not Implemented",
        502: "Bad Gateway",
        503: "Service Unavailable",
        504: "Gateway Timeout",
        505: "HTTP Version Not Supported",
        506: "Variant Also Negotiates",
        507: "Insufficient Storage", // WebDAV
        508: "Loop Detected", // WebDAV
        510: "Not Extended",
        511: "Network Authentication Required"
    ]
}

extension URLRequest {
    init(httpMethod: String, baseURL: URL, path: String) {
        self.init(url: baseURL.appending(path: path))
        self.httpMethod = httpMethod
    }
}
