import SwiftUI
import Foundation

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
