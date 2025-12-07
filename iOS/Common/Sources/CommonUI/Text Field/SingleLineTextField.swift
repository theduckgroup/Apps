import Combine
import UIKit
import SwiftUI

/// Text field implemented with `UITextField` and with additional features.
///
/// Features:
/// - Editing restriction (alphanumerics, digits, etc)
/// - Caret automatically moves to end of text when editing begins
/// - Left view can be set to magnifying glass (like in search bar)
/// - Clear button
/// - Callbacks when editing begins and ends
/// - `UITextField` attributes
/// - Proxy for accessing underlying `UITextField`
/// - Text binding is trimmed
///
/// Examples:
/// ```
/// SingleLineTextField(text: $text)
///   .textAlignment(.right)
///   .keyboardType(.numbersAndPunctuation)
///   .textValidation(.decimalNumber)
///   .onBeginEditing { ... }
///   .onEndEditing { ... }
///
/// SingleLineTextField("Search", text: $text)
///   .leftView(.magnifyingGlass) // Search icon
///   .clearButtonMode(.whileEditing)
/// ```
public struct SingleLineTextField: View {
    public var placeholder: String
    @Binding public var text: String
    public var bindingUpdateMode: TextFieldBindingUpdateMode = .immediate
    public var textStyle: UIFont.TextStyle
    public var textColor: Color
    public var textFieldVerticalPadding: CGFloat = 0
    public var textAlignment: NSTextAlignment = .left
    public var leftView: LeftView? = nil
    public var clearButtonMode: UITextField.ViewMode = .never
    public var keyboardType: UIKeyboardType = .default
    public var returnKeyType: UIReturnKeyType = .default
    public var autocapitalizationType: UITextAutocapitalizationType = .sentences
    public var spellCheckingType: UITextSpellCheckingType = .default
    public var textValidation: EditingRestriction?
    public var onBeginEditing: (() -> Void)?
    public var onEndEditing: (() -> Void)?
    public var onReturn: (() -> Void)?
    public var proxy: Proxy?
    @State internal var internalText: String
    
    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        textStyle: UIFont.TextStyle = .body,
        textColor: Color = .secondary
    ) {
        self.placeholder = placeholder
        self._text = text
        self.internalText = text.wrappedValue
        self.textStyle = textStyle
        self.textColor = textColor
    }
    
    public var body: some View {
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let height = ContentView.fittingSizeForTextField(font: font).height + textFieldVerticalPadding * 2
        
        GeometryReader { geometryProxy in
            ContentView(view: self, geometryProxy: geometryProxy)
        }
        .frame(height: height)
        .onChange(of: text) { _, newValue in
            // Update internalText only if the difference is not leading and trailing spaces
            
            if internalText.trimmed() != newValue.trimmed() {
                internalText = newValue
            }
        }
    }
    
    public func textAlignment(_ value: NSTextAlignment) -> Self {
        mutated(\.textAlignment, value)
    }
    
    /// Sets text field top and bottom padding.
    ///
    /// Unlike `View.padding()`, this padding is added inside the text field. When used with built-in
    /// iOS keyboard avoidance, this will add extra spacing between keyboard and the text field.
    public func textFieldVerticalPadding(_ value: CGFloat) -> Self {
        mutated(\.textFieldVerticalPadding, value)
    }
        
    public func leftView(_ value: LeftView?) -> Self {
        mutated(\.leftView, value)
    }
    
    public func clearButtonMode(_ value: UITextField.ViewMode) -> Self {
        mutated(\.clearButtonMode, value)
    }
    
    public func keyboardType(_ value: UIKeyboardType) -> Self {
        mutated(\.keyboardType, value)
    }
    
    public func returnKeyType(_ value: UIReturnKeyType) -> Self {
        mutated(\.returnKeyType, value)
    }
    
    public func autocapitalizationType(_ value: UITextAutocapitalizationType) -> Self {
        mutated(\.autocapitalizationType, value)
    }
    
    public func spellCheckingType(_ value: UITextSpellCheckingType) -> Self {
        mutated(\.spellCheckingType, value)
    }
    
    public func editingRestriction(_ value: EditingRestriction?) -> Self {
        mutated(\.textValidation, value)
    }
    
    public func onBeginEditing(_ value: (() -> Void)?) -> Self {
        mutated(\.onBeginEditing, value)
    }
    
    public func onEndEditing(_ value: (() -> Void)?) -> Self {
        mutated(\.onEndEditing, value)
    }
    
    public func onReturn(_ value: (() -> Void)?) -> Self {
        mutated(\.onReturn, value)
    }
    
    public func proxy(_ value: Proxy?) -> Self {
        mutated(\.proxy, value)
    }
}

extension SingleLineTextField {
    public enum LeftView {
        /// Magnifying glass/search icon (typically for search fields).
        case magnifyingGlass
        
        /// Activity indicator.
        case activityIndicator
    }
    
    /// Restriction of what user can type.
    public enum EditingRestriction {
        /// Alphanumeric characters (`CharacterSet.alphanumerics`) are allowed.
        case alphanumerics
        
        /// Digits (0-9) are allowed.
        case digits
        
        /// Validation for decimal number.
        case decimalNumber
    }
    
    /// A workaround to focus and unfocus a `UITextField` in SwiftUI.
    ///
    /// For iOS 15+, use `@FocusState` which also has effects on `UITextField`. See documentation [here](https://developer.apple.com/documentation/swiftui/focusstate).
    public class Proxy {
        weak var textField: UITextField?
        
        public init() {}
        
        public func beginEditing() {
            textField?.becomeFirstResponder()
        }
        
        public func endEditing() {
            textField?.resignFirstResponder()
        }
    }
}

private struct ContentView: UIViewRepresentable {
    let view: SingleLineTextField
    let geometryProxy: GeometryProxy
    @Environment(\.autocorrectionDisabled) private var autocorrectionDisabled
    
    func makeUIView(context: Context) -> UITextField {
        let textField = Self.createTextField()
        context.coordinator.textFieldCreated(textField)

        invalidateAttributes(textField, context)

        return textField
    }

    public func updateUIView(_ textField: UITextField, context: Context) {
        view.proxy?.textField = textField
        context.coordinator.view = self.view
        
        invalidateAttributes(textField, context)
        textField.text = view.internalText
        
        // Width constraint
        
        if let widthConstraint = context.coordinator.widthConstraint {
            widthConstraint.constant = geometryProxy.size.width
            
        } else {
            let widthConstraint = textField.widthAnchor.constraint(equalToConstant: geometryProxy.size.width)
            NSLayoutConstraint.activate([widthConstraint])
            
            context.coordinator.widthConstraint = widthConstraint
        }
    }
    
    private func invalidateAttributes(_ textField: UITextField, _ context: Context) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.clipsToBounds = true
        textField.placeholder = view.placeholder
        textField.font = .preferredFont(forTextStyle: view.textStyle)
        textField.textColor = UIColor(view.textColor)
        textField.textAlignment = view.textAlignment
        textField.keyboardType = view.keyboardType
        textField.returnKeyType = view.returnKeyType
        textField.clearButtonMode = view.clearButtonMode
        textField.autocapitalizationType = view.autocapitalizationType
        textField.autocorrectionType = autocorrectionDisabled ? .no : .yes
        textField.spellCheckingType = view.spellCheckingType
        
        invalidateLeftView(textField, context)
    }
    
    private func invalidateLeftView(_ textField: UITextField, _ context: Context) {
        let coordinator = context.coordinator
        
        guard coordinator.previousLeftView != view.leftView else {
            return
        }
        
        defer {
            coordinator.previousLeftView = view.leftView
        }
        
        let fontPointSize = UIFont.preferredFont(forTextStyle: view.textStyle).pointSize
        
        switch view.leftView {
        case nil:
            textField.leftView = nil
            textField.leftViewMode = .never
            
        case .magnifyingGlass:
            let leftView = UIImageView()
            
            leftView.image = UIImage(
                systemName: "magnifyingglass",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: fontPointSize)
            )
            
            leftView.contentMode = .center
            leftView.tintColor = .secondaryLabel
            textField.leftView = leftView
            textField.leftViewMode = .always
            
            leftView.removeConstraints(leftView.constraints.filter { $0.firstAttribute == .width })
            NSLayoutConstraint.activate([leftView.widthAnchor.constraint(equalToConstant: fontPointSize * 1.75)])
            
        case .activityIndicator:
            let leftView = UIActivityIndicatorView(style: .medium)
            leftView.color = .secondaryLabel
            leftView.startAnimating()
            leftView.transform = .init(scaleX: 0.9, y: 0.9)
            textField.leftView = leftView
            textField.leftViewMode = .always

            leftView.removeConstraints(leftView.constraints.filter { $0.firstAttribute == .width })
            NSLayoutConstraint.activate([leftView.widthAnchor.constraint(equalToConstant: fontPointSize * 1.75)])
        }
    }
    
    func makeCoordinator() -> Coordinator {
        .init(view: self.view)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var view: SingleLineTextField
        var widthConstraint: NSLayoutConstraint?
        var previousLeftView: SingleLineTextField.LeftView?
        
        init(view: SingleLineTextField) {
            self.view = view
        }
        
        func textFieldCreated(_ textField: UITextField) {
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
            textField.addTarget(self, action: #selector(textFieldEditingDidBegin), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(textFieldEditingDidEnd), for: .editingDidEnd)
        }
        
        @objc func textFieldEditingChanged(_ textField: UITextField) {
            let text = textField.text ?? ""
            view.internalText = text
            
            if view.bindingUpdateMode == .immediate {
                view.text = text.trimmed()
            }
        }
        
        @objc func textFieldEditingDidBegin(_ textField: UITextField) {
            view.onBeginEditing?()
            
            // Move to the end of text
            // Does not work without delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let newPosition = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
        
        @objc func textFieldEditingDidEnd(_ textField: UITextField) {
            switch view.textValidation {
            case nil:
                break
                
            case .alphanumerics:
                let existing = view.text
                
                let disallowedSet = CharacterSet.alphanumerics.inverted
                
                if existing.rangeOfCharacter(from: disallowedSet) != nil {
                    view.internalText = ""
                    view.text = ""
                }
                
            case .digits:
                let existing = view.text

                let disallowedSet = CharacterSet(charactersIn: "0123456789").inverted
                if existing.rangeOfCharacter(from: disallowedSet) != nil {
                    view.internalText = ""
                    view.text = ""
                }
                
            case .decimalNumber:
                let existing = view.text

                let disallowedSet = CharacterSet(charactersIn: ".0123456789").inverted
                if existing.rangeOfCharacter(from: disallowedSet) != nil ||
                    existing.count(where: { $0 == "." })  > 1 { // cant have multiple periods in a decimal number.
                    view.internalText = ""
                    view.text = ""
                }
            }
            
            view.internalText = view.internalText.trimmed()
            
            if view.bindingUpdateMode == .onEndEditing {
                view.text = view.internalText
            }

            view.onEndEditing?()
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            view.onReturn?()
            
            return true
        }
        
        @objc func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let existingString = (textField.text ?? "") as NSString
            
            switch view.textValidation {
            case nil:
                return true
                
            case .alphanumerics:
                let proposedString = String(existingString.replacingCharacters(in: range, with: string))
                let disallowedSet = CharacterSet.alphanumerics.inverted
                return proposedString.rangeOfCharacter(from: disallowedSet) == nil
            
            case .digits:
                let proposedString = String(existingString.replacingCharacters(in: range, with: string))
                
                let disallowedSet = CharacterSet(charactersIn: "0123456789").inverted
                return proposedString.rangeOfCharacter(from: disallowedSet) == nil
                
            case .decimalNumber:
                let proposedString = String(existingString.replacingCharacters(in: range, with: string))
                
                if proposedString.filter({ $0 == "." }).count > 1 {
                    return false
                }
                let disallowedSet = CharacterSet(charactersIn: ".0123456789").inverted
                return proposedString.rangeOfCharacter(from: disallowedSet) == nil
            }
        }
    }
}

extension ContentView {
    static func fittingSizeForTextField(font: UIFont) -> CGSize {
        measuringTextField.font = font
        
        return measuringTextField.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    static private let measuringTextField = createTextField()
    
    static func createTextField() -> UITextField {
        UITextField()
    }
}

private extension String {
    func removeCharacters(from forbiddenCharacterSet: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenCharacterSet.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }
}

#Preview {
    PreviewView()
}

private struct PreviewView: View {
    @State var text = "Hello"
    @State var proxy = SingleLineTextField.Proxy()
    
    var body: some View {
        VStack {
            SingleLineTextField("Enter text", text: $text, textStyle: .body, textColor: .secondary)
                .proxy(proxy)
                .onBeginEditing { print("Began editing") }
                .onEndEditing { print("Ended editing") }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .border(Color(.separator))
                .frame(width: 270)
                
            HStack {
                Button("Begin Editing") { proxy.beginEditing() }
                Button("End Editing") { proxy.endEditing() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
