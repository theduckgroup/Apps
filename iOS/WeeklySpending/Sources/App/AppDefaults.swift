import SwiftUI
import Common
import CommonUI

@Observable
@dynamicMemberLookup
class AppDefaults {
    static let storageKey = "appDefaults"
    
    init() {
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
            UserDefaults.standard.set(rawData, forKey: "appDefaults")
        }
    }
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Data, T>) -> T {
        get {
            data[keyPath: keyPath]
        }
        set {
            data[keyPath: keyPath] = newValue
        }
    }
}

extension AppDefaults {
    struct Data: Codable {
        var colorSchemeOverride: ColorSchemeOverride?
        var accentColorData: ColorData = ColorData(Color.theme)
        
        var accentColor: Color {
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
