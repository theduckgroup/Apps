import Foundation
import UIKit

public extension UIColor {
    // Theme
    
    // Original: #042434 | oklch(0.2464 0.0474 234.89)
    // Theme colors are calculated by changing original's chroma to 0.1, then varying lightness
    // Use OKCLH picker: https://oklch.com/
    // Make sure you use okclh format rather than rgb to avoid conversion errors
    // `light` is used for dark UI style, `dark` is used for light UI style
    
    static let theme = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.themeLight : UIColor.themeDark
    }
    
    static let themeLight = UIColor(hex: 0x3989b3) // oklch(0.6 0.1 234.89)
    static let themeDark = UIColor(hex: 0x126b94) // oklch(0.5 0.1 234.89)
    
    // Mantine teal
    
    static let mantineTeal = UIColor {traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.mantineTealLight : UIColor.mantineTealDark
    }
    
    static let mantineTealLight = UIColor(hex: 0x079268)
    static let mantineTealDark = UIColor(hex: 0x079268)
    
    // Old theme
    
    // static let themeLight = UIColor(hex: 0x2E7DB1)
    // static let themeDark = UIColor(hex: 0x2C6494)
}
