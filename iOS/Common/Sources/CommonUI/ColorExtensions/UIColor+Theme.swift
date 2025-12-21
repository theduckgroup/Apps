import Foundation
import UIKit

public extension UIColor {
    // Original: #042434 | oklch(0.2464 0.0474 234.89)
    // Theme colors are calculated by changing original's chroma to 0.1, then varying lightness
    // Use OKCLH picker: https://oklch.com/
    // Make sure you use okclh format rather than rgb to avoid conversion errors
    
    /// Lighter theme color (used for dark UI style, e.g. text on top of dark background).
    static let themeLight = UIColor(hex: 0x3989b3) // oklch(0.6 0.1 234.89)
    
    /// Darker theme color (used for light UI style, e.g. text on top of light background).
    static let themeDark = UIColor(hex: 0x126b94) // oklch(0.5 0.1 234.89)
    
    // Old colors
    // static let themeLight = UIColor(hex: 0x2E7DB1)
    // static let themeDark = UIColor(hex: 0x2C6494)
}
