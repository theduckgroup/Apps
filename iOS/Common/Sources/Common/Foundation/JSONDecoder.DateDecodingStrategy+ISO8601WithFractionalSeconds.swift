import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                  debugDescription: "Invalid date in iso8601withSeconds: " + string)
        }
        return date
    }
}
