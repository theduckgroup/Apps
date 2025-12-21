public import SwiftUI
import Common
public import CommonUI

@Observable
@dynamicMemberLookup
public class AppDefaults {
    public let storageKey: String
    
    public init(storageKey: String) {
        self.storageKey = storageKey
        
        if let rawData = UserDefaults.standard.data(forKey: storageKey) {
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
            UserDefaults.standard.set(rawData, forKey: storageKey)
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

public extension AppDefaults {
    struct Data: Codable {
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

public extension AppDefaults {
    static let mock = AppDefaults(storageKey: "AppDefaults:mock")
}
