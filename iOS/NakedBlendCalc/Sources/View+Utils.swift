import SwiftUI
import UIKit

// Keyboard done button

extension View {
    @ViewBuilder
    func addKeyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Done") {
                    UIApplication.dismissKeyboard()
                }
                .font(.body.bold())
            }
        }
    }
}

extension UIApplication {
    static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Keyboard height

extension View {
    func keyboardHeight(_ value: Binding<CGFloat>) -> some View {
        modifier(KeyboardHeightModifier(keyboardHeight: value))
    }
}

private struct KeyboardHeightModifier: ViewModifier {
    var keyboardHeight: Binding<CGFloat>
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let userInfo = notification.userInfo,
                      let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                                                            
                self.keyboardHeight.wrappedValue = keyboardRect.height
                
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                self.keyboardHeight.wrappedValue = 0
            }
    }
}

//

extension View {
    @ViewBuilder
    func infiniteMaxWidth(alignment: Alignment = .leading) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
}

//

extension EnvironmentValues {
    var scrollViewProxy: ScrollViewProxy? {
        get { self[ScrollViewProxyKey.self] }
        set { self[ScrollViewProxyKey.self] = newValue }
    }
}

private struct ScrollViewProxyKey: EnvironmentKey {
    static let defaultValue: ScrollViewProxy? = nil
}

// Color from hex

extension Color {
    init(hex: Int, opacity: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}

extension UIColor {
    /// Color from hex code and alpha.
    ///
    /// Examples:
    /// ```
    /// UIColor(hex: 0x4020A5)
    /// UIColor(hex: 0x4020A5, alpha: 0.5)
    /// ```
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

