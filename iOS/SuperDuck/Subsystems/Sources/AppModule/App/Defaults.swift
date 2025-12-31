public import SwiftUI
import Common
public import CommonUI

@Observable
@dynamicMemberLookup
public class Defaults {
    public let storageKey: String = "App:defaults"
    
    public init() {
        data = Persistence.value(for: storageKey) ?? .init()
    }
    
    private var data: Data {
        didSet {
            Persistence.setValue(data, for: storageKey)
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

public extension Defaults {
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
