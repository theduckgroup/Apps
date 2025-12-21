import Foundation
import SwiftUI

public extension Color {
    /// Compares with other color approximately.
    ///
    /// Even though `Color` is `Equatable`, it often returns `false` on device for identical colors
    /// for some reason. Use this instead.
    func isApproximatelyEqualTo(_ other: Color) -> Bool {
        let (r1, g1, b1, a1) = UIColor(self).getRGBA()
        let (r2, g2, b2, a2) = UIColor(other).getRGBA()
        
        return (
            abs(r1 - r2) < 0.01 &&
            abs(g1 - g2) < 0.01 &&
            abs(b1 - b2) < 0.01 &&
            abs(a1 - a2) < 0.01
        )
    }
}

private extension UIColor {
    func getRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
