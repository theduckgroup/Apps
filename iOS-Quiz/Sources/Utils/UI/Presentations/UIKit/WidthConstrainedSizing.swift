import Foundation
import CoreGraphics

/// An object whose preferred size changes with available width. Usually a view with multi-line text in it.
public protocol WidthConstrainedSizing {
    /// Desired size given a width
    func preferredSize(withConstrainedWidth width: CGFloat) -> CGSize
    
    /// Apply a width constraint
    func constrainWidth(to width: CGFloat)
}
