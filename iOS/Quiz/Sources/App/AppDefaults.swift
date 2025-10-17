import SwiftUI
import Common

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
    }
}

public enum DynamicTypeSizeOverride: String, RawRepresentable, CaseIterable, Codable {
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    
    public init?(from unbacked: DynamicTypeSize) {
        switch unbacked {
        case .xSmall: self = .xSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .xLarge
        case .xxLarge: self = .xxLarge
        case .xxxLarge: self = .xxxLarge
        case .accessibility1: return nil
        case .accessibility2: return nil
        case .accessibility3: return nil
        case .accessibility4: return nil
        case .accessibility5: return nil
        @unknown default: return nil
        }
    }
    
    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .xSmall: .xSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .xLarge
        case .xxLarge: .xxLarge
        case .xxxLarge: .xxxLarge
        }
    }
}

public enum ColorSchemeOverride: String, RawRepresentable, CaseIterable, Codable {
    case dark
    case light
    
    public init?(from colorScheme: ColorScheme) {
        switch colorScheme {
        case .light: self = .light
        case .dark: self = .dark
        @unknown default: return nil
        }
    }
    
    public var colorScheme: ColorScheme {
        switch self {
        case .dark: .dark
        case .light: .light
        
        }
    }
}
