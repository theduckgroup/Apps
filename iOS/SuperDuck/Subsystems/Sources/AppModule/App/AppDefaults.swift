public import SwiftUI
import Common
public import CommonUI

@Observable
@dynamicMemberLookup
public class AppDefaults {
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

public extension AppDefaults {
    struct Data {
        public var colorSchemeOverride: ColorSchemeOverride?
        public var accentColor: Color = Color.theme
        public var hiddenTabViewItems: [TabViewItem] = []
    }
}

extension AppDefaults.Data: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.colorSchemeOverride = try container.decodeIfPresent(ColorSchemeOverride.self, forKey: .colorSchemeOverride)
        self.accentColor = try container.decode(ColorData.self, forKey: .accentColor).color
        self.hiddenTabViewItems = try container.decodeIfPresent([TabViewItem].self, forKey: .hiddenTabViewItems) ?? []
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(colorSchemeOverride, forKey: .colorSchemeOverride)
        try container.encode(ColorData(accentColor), forKey: .accentColor)
        try container.encode(hiddenTabViewItems, forKey: .hiddenTabViewItems)
    }
            
    enum CodingKeys: String, CodingKey {
        case colorSchemeOverride
        case accentColor
        case hiddenTabViewItems
    }
}
