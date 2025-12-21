public import SwiftUI
import Common
public import CommonUI

public extension AppDefaults {
    static let shared = AppDefaults()
}

@Observable
@dynamicMemberLookup
public class AppDefaults {
    static private let storageKey = "appDefaultsV2"
    
    private init() {
        if let rawData = UserDefaults.standard.data(forKey: Self.storageKey) {
            do {
                self.data = try JSONDecoder().decode(Data.self, from: rawData)
                
            } catch {
                data = Data()
                logger.error("Unable to decode AppDefaults data: \(error)")
                assertionFailure()
            }
        } else {
            data = Data()
        }
    }
    
    private var data: Data {
        didSet {
            let rawData = try! JSONEncoder().encode(data)
            UserDefaults.standard.set(rawData, forKey: Self.storageKey)
        }
    }
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Data, T>) -> T {
        get {
            data[keyPath: keyPath]
        }
        set {
            data[keyPath: keyPath] = newValue
        }
    }
}

extension AppDefaults {
    public struct Data: Codable {
        public var colorSchemeOverride: ColorSchemeOverride?
        private var accentColorData: ColorData = ColorData(Color.theme)
        
        public var accentColor: Color {
            get {
                accentColorData.color
            }
            set {
                accentColorData = ColorData(newValue)
            }
        }
                
        enum CodingKeys: String, CodingKey {
            case colorSchemeOverride
            case accentColorData = "accentColor"
        }
    }
}
