import Foundation

public class Persistence {
    public static func setValue<T: Codable>(_ value: T, for key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to encode value for key '\(key)': \(error)")
        }
    }

    public static func value<T: Codable>(for key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to decode value for key '\(key)': \(error)")
            return nil
        }
    }
}
