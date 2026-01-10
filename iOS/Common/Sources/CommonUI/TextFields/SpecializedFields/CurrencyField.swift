import SwiftUI

public struct CurrencyField: View {
    var placeholder: String
    @Binding var value: Decimal
    var isCredit: Bool
    var currencySymbol: String = "$"
    var fractionLength: Int = 2
    var onFocus: () -> Void
    @State private var text: String
    @FocusState private var focused
    
    public init(
        _ placeholder: String,
        value: Binding<Decimal>,
        isCredit: Bool = false,
        onFocus: @escaping () -> Void = { }
    ) {
        self.placeholder = placeholder
        self._value = value
        self.isCredit = isCredit
        self.onFocus = onFocus
        self.text = Self.formatForDisplay(value.wrappedValue)
    }
    
    public var body: some View {
        TextField(placeholder, text: $text)
            .focused($focused)
            .multilineTextAlignment(.leading)
            .keyboardType(.decimalPad)
            .onTapGesture {
                focused = true
            }
            .onChange(of: text) {
                textChanged()
            }
            .onChange(of: value) {
                valueChanged()
            }
            .onChange(of: focused) {
                focusedChanged()
            }
    }
    
    private func textChanged() {
        do {
            if text == "" {
                value = 0
                
            } else {
                // This works for both "123456" and "$123,456"
                value = abs(try Decimal(text, format: .currency(code: "AUD").locale(Locale(identifier: "en_AU"))))
                
                if isCredit {
                    value = -value
                }
            }
            
        } catch {
            // Unable to parse text
            // Just keep the old value; if user leaves the text field then it just reverts to old text
            print("Unable to parse '\(text)': \(error)")
            // assertionFailure()
        }
    }
    
    private func valueChanged() {
        if !focused {
            text = formatForDisplay(value)
        }
    }
    
    private func focusedChanged() {
        if focused {
            if value == 0 {
                text = ""
                
            } else {
                text = formatForEditing(value)
            }
            
            onFocus()
            
        } else {
            text = formatForDisplay(value)
        }
    }
    
    private func formatForDisplay(_ value: Decimal) -> String {
        Self.formatForDisplay(value)
    }
    
    private static func formatForDisplay(_ value: Decimal) -> String {
        if value == 0 {
            value.formatted(.currency(code: "AUD").precision(.fractionLength(0)))
        } else {
            value.formatted(.currency(code: "AUD"))
        }
    }
    
    private func formatForEditing(_ value: Decimal) -> String {
        value.formatted(
            .number
                .grouping(.never)
        )
    }
}
