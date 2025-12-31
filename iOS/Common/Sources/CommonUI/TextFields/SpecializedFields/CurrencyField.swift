import SwiftUI

public struct CurrencyField: View {
    var placeholder: String
    @Binding var value: Decimal
    var currencySymbol: String = "$"
    var fractionLength: Int = 2
    var onFocus: () -> Void
    @State private var text: String
    @FocusState private var focused
    
    public init(
        _ placeholder: String,
        value: Binding<Decimal>,
        onFocus: @escaping () -> Void = { }
    ) {
        self.placeholder = placeholder
        self._value = value
        self.text = Self.formatValue(value.wrappedValue, fractionLength: fractionLength, currencySymbol: currencySymbol)
        self.onFocus = onFocus
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
                value = try Decimal(text, format: .currency(code: "AUD").locale(Locale(identifier: "en_AU")))
            }
            
        } catch {
            print("Unable to parse '\(text)': \(error)")
            // assertionFailure()
        }
    }
    
    private func valueChanged() {
        if !focused {
            text = Self.formatValue(value, fractionLength: fractionLength, currencySymbol: currencySymbol)
        }
    }
    
    private func focusedChanged() {
        if focused {
            if value == 0 {
                text = ""
                
            } else {
                text = Self.formatValue(value, fractionLength: fractionLength)
                // print("1 Set text to \(text)")
            }
            
            onFocus()
            
        } else {
            text = Self.formatValue(value, fractionLength: fractionLength, currencySymbol: currencySymbol)
            // print("2 Set text to \(text), unit = \(unit ?? "nil")")
        }
    }
    
    /// Formats value with currency symbol.
    private static func formatValue(_ value: Decimal, fractionLength: Int, currencySymbol: String) -> String {
        currencySymbol + formatValue(value, fractionLength: fractionLength)
    }
    
    /// Formats value without currency symbol.
    private static func formatValue(_ value: Decimal, fractionLength: Int) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...fractionLength))
                .grouping(.automatic)
        )
    }
}
