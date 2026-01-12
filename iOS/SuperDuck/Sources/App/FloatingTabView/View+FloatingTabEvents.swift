import Foundation
import SwiftUI

extension EnvironmentValues {
    @Entry var floatingTabSelected = false
}

extension View {
    @ViewBuilder
    func onFloatingTabSelected(_ action: @escaping () -> Void) -> some View {
        modifier(FloatingTabSelectedModifier(action: action))
    }
    
    @ViewBuilder
    func onFloatingTabFirstSelected(_ action: @escaping () -> Void) -> some View {
        modifier(FloatingTabFirstSelectedModifier(action: action))
    }
    
    @ViewBuilder
    func onFloatingTabDeselected(_ action: @escaping () -> Void) -> some View {
        modifier(FloatingTabDeselectedModifier(action: action))
    }
}

private struct FloatingTabSelectedModifier: ViewModifier {
    @Environment(\.floatingTabSelected) var isFloatingTabSelected
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onChange(of: isFloatingTabSelected) { _, newValue in
            if newValue {
                action()
            }
        }
    }
}

private struct FloatingTabFirstSelectedModifier: ViewModifier {
    @Environment(\.floatingTabSelected) var isFloatingTabSelected
    @State private var wasSelectedOnce = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onChange(of: isFloatingTabSelected) { _, newValue in
            if newValue && !wasSelectedOnce {
                wasSelectedOnce = true
                action()
            }
        }
    }
}

private struct FloatingTabDeselectedModifier: ViewModifier {
    @Environment(\.floatingTabSelected) var isFloatingTabSelected
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onChange(of: isFloatingTabSelected) { _, newValue in
            if !newValue {
                action()
            }
        }
    }
}
