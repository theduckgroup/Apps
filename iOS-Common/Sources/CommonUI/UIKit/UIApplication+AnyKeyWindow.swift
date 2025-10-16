import UIKit
import Common

public extension UIApplication {
    /// A key window.
    ///
    /// - Important: This property **can** return `nil` (even in places where it seems impossible).
    var anyKeyWindow: UIWindow? {
        let windowScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        
        let preferredActivationStates: [UIScene.ActivationState] = [
            .foregroundActive,
            .foregroundInactive,
            .background,
            .unattached
        ]
        
        return windowScenes
            .min(on: { preferredActivationStates.firstIndex(of: $0.activationState) ?? Int.max })?
            .keyWindow
    }
}
