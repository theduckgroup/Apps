import SwiftUI
import UIKit

/// Multiline text field.
///
/// Features:
/// - Placeholder text
/// - Minimum height
/// - Automatically change height when user types long text
/// - Insert new line character when user begins editing
/// - Commit handler block
/// - Proxy for focus/unfocus
/// - Text binding is trimmed
public struct MultilineTextField: View {
    // See: https://stackoverflow.com/questions/56471973/how-do-i-create-a-multiline-textfield-in-swiftui?rq=1
    
    // `text` is the (external) text binding while `internalText` is the text that is in the text
    // field. When the text field changes, `text` is set to the trimmed text while `internalText`
    // is set to the original text. This setup is required for correct height calculations because
    // newlines are also trimmed.
    
    public var placeholder: String
    @Binding public var text: String
    public var editable: Bool
    public var font: UIFont
    public var textColor: UIColor
    public var updatesBindingImmediately = true
    public var minimumHeight: CGFloat = 0
    public var mininumNumberOfLines: Int = 0
    public var insertsNewLineOnBeginEditing = false
    public var pasteDisabled: Bool = false
    public var onEndEditing: (() -> Void)?
    public var proxy: Proxy?
    @State internal var internalText: String
    @State private var height: CGFloat = 0
    
    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        editable: Bool = true,
        font: UIFont = .preferredFont(forTextStyle: .subheadline),
        textColor: UIColor = .secondaryLabel
    ) {
        self.placeholder = placeholder
        self._text = text
        self.internalText = text.wrappedValue
        self.editable = editable
        self.font = font
        self.textColor = textColor
    }
    
    /// If `true` binding is updated immediately as user types, otherwise it will be updated when
    /// editing ends.
    ///
    /// - Important: If set to `false`, make sure to unfocus the text field to trigger binding update.
    public func updatesBindingImmediately(_ value: Bool) -> Self {
        mutated(\.updatesBindingImmediately, value)
    }
    
    public func minimumHeight(_ value: CGFloat) -> Self {
        mutated(\.minimumHeight, value)
    }
    
    public func minimumNumberOfLines(_ value: Int) -> Self {
        mutated(\.mininumNumberOfLines, value)
    }
    
    public func insertsNewLineOnBeginEditing(_ value: Bool) -> Self {
        mutated(\.insertsNewLineOnBeginEditing, value)
    }
    
    public func pasteDisabled(_ value: Bool) -> Self {
        mutated(\.pasteDisabled, value)
    }
    
    public func onEndEditing(_ value: @escaping () -> Void) -> Self {
        mutated(\.onEndEditing, value)
    }
    
    public func proxy(_ value: Proxy?) -> Self {
        mutated(\.proxy, value)
    }
    
    public var body: some View {
        GeometryReader { geometryProxy in
            // Height is "transferred" from inside GeometryReader to outside via preference key
            // Cannot be set ouside of GeometryReader because it depends on geometryProxy
            // Cannot just write `self.height = height` because states cannot be modified while view is being rendered
             
            let height = self.computeHeight(geometryProxy)
            
            UITextViewRepresentable(
                view: self
            )
            .background(placeholderView(), alignment: .topLeading)
            .preference(key: HeightPreferenceKey.self, value: height) // Write height
        }
        .onPreferenceChange(HeightPreferenceKey.self) { // Read height
            self.height = $0 // Set height state
        }
        .frame(height: self.height) // Set height
        .onChange(of: text) { _, newValue in
            // Update internalText only if the difference is not leading and trailing spaces
            
            if internalText.trimmed() != newValue.trimmed() {
                internalText = newValue
            }
        }
    }
    
    private func computeHeight(_ geometryProxy: GeometryProxy) -> CGFloat {
        if editable {
            let textHeight = fittingHeight(text: internalText, geometryProxy)
            let placeholderHeight = fittingHeight(text: placeholder, geometryProxy)
            let minimumHeightFromLines = font.lineHeight * CGFloat(self.mininumNumberOfLines)
            return max(textHeight, placeholderHeight, self.minimumHeight, minimumHeightFromLines)
            
        } else {
            let textHeight = fittingHeight(text: internalText, geometryProxy)
            let placeholderHeight = internalText.isEmpty ? fittingHeight(text: placeholder, geometryProxy) : 0
            return max(textHeight, placeholderHeight)
        }
    }
    
    private func fittingHeight(text: String, _ geometryProxy: GeometryProxy) -> CGFloat {
        UITextViewRepresentable.fittingSizeForTextView(text: text, font: self.font, width: geometryProxy.size.width).height
    }

    @ViewBuilder
    private func placeholderView() -> some View {
        if internalText.isEmpty {
            Text(placeholder)
                .foregroundColor(Color(.placeholderText))
                .font(Font(self.font as CTFont))
                .multilineTextAlignment(.leading)
        }
    }
}

extension MultilineTextField {
    public class Proxy {
        var textView: UITextView?
        public init() {}
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // This never gets called, probably because there is only one view that propagates the preference
        value = max(value, nextValue())
    }
}

private struct UITextViewRepresentable: UIViewRepresentable {
    let view: MultilineTextField
    @Environment(\.autocorrectionDisabled) var autocorrectionDisabled // DOES THIS WORK??
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func makeUIView(context: Context) -> UITextView {
        let textView = Self.createTextView()
        context.coordinator.textViewCreated(textView)
        updateAttributes(textView)        
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        view.proxy?.textView = textView
        
        context.coordinator.view = view
        
        textView.text = view.internalText
        updateAttributes(textView)
    }
    
    private func updateAttributes(_ textView: UITextView) {
        print("Update dynamicTypeSize = \(dynamicTypeSize) ")
        textView.minimumContentSizeCategory = .init(dynamicTypeSize)
        textView.maximumContentSizeCategory = .init(dynamicTypeSize)
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = view.editable
        textView.font = view.font
        textView.textColor = view.textColor
        textView.autocorrectionType = autocorrectionDisabled ? .no : .default
    }

    func makeCoordinator() -> Coordinator {
        .init(view: view)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var view: MultilineTextField
        
        init(view: MultilineTextField) {
            self.view = view
        }
        
        func textViewCreated(_ textView: UITextView) {
            textView.delegate = self
        }

        func textViewDidChange(_ textView: UITextView) {
            view.internalText = textView.text
            
            if view.updatesBindingImmediately {
                view.text = textView.text.trimmed()
            }
        }
        
        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            if view.insertsNewLineOnBeginEditing {
                // needs to be temporarily disabled or else initial tap on misspelled word
                // will display auto correct popover at end of text and not on mispelled word.
                textView.autocorrectionType = .no
            }
            
            return true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if view.insertsNewLineOnBeginEditing {
                let text = view.internalText
                
                let needsNewLine = !text.trimmed().isEmpty
                    && text.last != "\n"
                
                if needsNewLine {
                    view.internalText = text + "\n"
                    // Don't need to update view.text because difference is only the newline
                }
                
                // async or else cursor is not moved to the end position
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    let endPosition = textView.endOfDocument
                    textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
                    textView.autocorrectionType = .yes
                }
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            view.internalText = view.internalText.trimmed()
            view.onEndEditing?()
            
            if !view.updatesBindingImmediately {
                view.text = view.internalText
            }
        }
    }
}

extension UITextViewRepresentable {
    static func fittingSizeForTextView(text: String, font: UIFont, width: CGFloat) -> CGSize {
        measuringTextView.text = text
        measuringTextView.font = font
        
        return measuringTextView.sizeThatFits(CGSize(width: width, height: CGFloat.infinity))
    }
    
    /// Text view used for measuring fitting size
    static let measuringTextView = createTextView()
    
    /// Creates a text view. Shared between `makeUIView` and `measuringTextView` to ensure identical appearance.
    static func createTextView() -> UITextView {
        let view = UITextView()
        
        view.isEditable = true
        view.textColor = .secondaryLabel
        view.isSelectable = true
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textAlignment = .left
        
        // Remove default padding
        // https://stackoverflow.com/a/20269793/1572953
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return view
    }
}

#Preview {
    PreviewView()
}

private struct PreviewView: View {
    @State var text = "Some very very very long description string to be initially wider than screen"
    @State var proxy = MultilineTextField.Proxy()
    
    var body: some View {
        VStack {
            MultilineTextField("Enter some text here", text: $text)
                .proxy(proxy)
                .onEndEditing { print("Editing ended: \(text)") }
                .insertsNewLineOnBeginEditing(true)
        }
        .padding()
    }
}
