import Foundation
import SwiftUI

public extension View {
    @ViewBuilder
    func onSceneBecomeActive(_ action: @escaping () -> Void) -> some View {
        modifier(OnSceneBecomeActiveModififer(action: action))
    }
}

private struct OnSceneBecomeActiveModififer: ViewModifier {
    @Environment(\.scenePhase) var scenePhase
    var action: () -> Void
    
    func body(content: Content) -> some View {
        content.onChange(of: scenePhase) {
            if scenePhase == .active {
                action()
            }
        }
    }
}
