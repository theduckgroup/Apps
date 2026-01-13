import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func floatingTabBarSafeAreaInset() -> some View {
        modifier(FloatingTabBarSafeAreaInsetModifier())
    }
}

private struct FloatingTabBarSafeAreaInsetModifier: ViewModifier {
    @Environment(\._floatingTabBarBottomInset) var floatingTabBarBottomInset
    
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: floatingTabBarBottomInset)
        }
    }
}
