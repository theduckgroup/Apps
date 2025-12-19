import Foundation
import SwiftUI

public extension Color {
    static let theme = Color(
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor.themeLight : UIColor.themeDark
        }
    )
    
    static let themeLight = Color(UIColor.themeLight)
    static let themeDark = Color(UIColor.themeDark)
    
    /// Very dark color used in NakedBlendCalc for nav bar, not useful for text etc.
    static let themeAlt2 = Color(hex: 0x153850)
}
