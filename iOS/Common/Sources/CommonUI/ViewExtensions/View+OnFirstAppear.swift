import Foundation
import SwiftUI

public extension View {
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
}

private struct OnFirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State var didAppear: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !didAppear {
                    action()
                    didAppear = true
                }
            }
    }
}
