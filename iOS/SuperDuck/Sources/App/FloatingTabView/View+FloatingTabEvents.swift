import Foundation
import SwiftUI
import CommonUI

extension EnvironmentValues {
    @Entry var isFloatingTabSelected = false
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
    @Environment(\.isFloatingTabSelected) var isFloatingTabSelected
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onFirstAppear {
                if isFloatingTabSelected {
                    action()
                }
            }
            .onChange(of: isFloatingTabSelected) { _, newValue in
                if newValue {
                    action()
                }
            }
    }
}

private struct FloatingTabFirstSelectedModifier: ViewModifier {
    @Environment(\.isFloatingTabSelected) var isFloatingTabSelected
    @State private var wasSelectedOnce = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onFirstAppear {
                if isFloatingTabSelected && !wasSelectedOnce {
                    wasSelectedOnce = true
                    action()
                }
            }
            .onChange(of: isFloatingTabSelected) { _, newValue in
                if newValue && !wasSelectedOnce {
                    wasSelectedOnce = true
                    action()
                }
            }
    }
}

private struct FloatingTabDeselectedModifier: ViewModifier {
    @Environment(\.isFloatingTabSelected) var isFloatingTabSelected
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onChange(of: isFloatingTabSelected) { _, newValue in
            if !newValue {
                action()
            }
        }
    }
}
