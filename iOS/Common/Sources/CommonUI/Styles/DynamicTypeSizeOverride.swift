import SwiftUI
import Foundation

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
