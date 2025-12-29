import Foundation
import SwiftUI

public extension Color {
    // Theme
    
    static let theme = Color(UIColor.theme)
    static let themeLight = Color(UIColor.themeLight)
    static let themeDark = Color(UIColor.themeDark)
    
    // Very dark color used in NakedBlendCalc for nav bar, not useful for text etc.
    
    static let themeAlt2 = Color(hex: 0x153850)
    
    // Mantine Teal
    
    static let mantineTeal = Color(UIColor.mantineTeal)
    static let mantineTealLight = Color(UIColor.mantineTealLight)
    static let mantineTealDark = Color(UIColor.mantineTealDark)
}
