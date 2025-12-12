import SwiftUI

/// Number field used in NakedBlendCalc.
///
/// - Note: This includes the label above the field and is only useful for NakedBlendCalc. If the
/// number field with unit is needed in the future, refactor it out.
struct NumberField: View {
    let name: String
    @Binding var value: Double
    var unit: String?
    var restriction: Restriction
    var onFocus: () -> Void
    @State private var text: String
    @FocusState private var focused
    @ScaledMetric private var fontSize: CGFloat = 20
    
    public init(
        _ name: String,
        _ value: Binding<Double>,
        unit: String? = nil,
        restriction: Restriction,
        onFocus: @escaping () -> Void = { }
    ) {
        self.name = name
        _value = value
        self.restriction = restriction
        self.unit = unit
        self.text = Self.formatValue(value.wrappedValue, unit, restriction)
        self.onFocus = onFocus
    }
    
    private var integer: Bool {
        restriction == .integer
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .font(.body.smallCaps().leading(.tight))
                .frame(maxHeight: .infinity, alignment: .bottom)
            
            TextField("", text: $text)
                .focused($focused)
                .font(.system(size: fontSize))
                .multilineTextAlignment(.leading)
                .frame(height: fontSize * 1.75)
                .keyboardType(integer ? .numberPad : .decimalPad)
        }
        .frame(minWidth: 60, alignment: .leading)
        // .fixedSize()
        .onTapGesture {
            focused = true
        }
        .onChange(of: text) { newValue in
            let x = text.components(separatedBy: " ").first ?? "" // Strip unit
            value = Double(x) ?? 0
        }
        .onChange(of: value) { newValue in
            if !focused {
                text = Self.formatValue(value, unit, restriction)
                // print("4 Set text to \(text)")
            }
        }
        .onChange(of: focused) { newValue in
            if focused {
                if value == 0 {
                    text = ""
                    
                } else {
                    text = Self.formatValue(value, restriction)
                    // print("1 Set text to \(text)")
                }
                
                onFocus()
                
            } else {
                text = Self.formatValue(value, unit, restriction)
                // print("2 Set text to \(text), unit = \(unit ?? "nil")")
            }
        }
    }
    
    /// Formats value with unit.
    private static func formatValue(_ value: Double, _ unit: String?, _ restriction: Restriction) -> String {
        var result = formatValue(value, restriction)
        
        if let unit {
            result += " \(unit)"
        }
        
        return result
    }
    
    /// Formats value without unit.
    private static func formatValue(_ value: Double, _ restriction: Restriction) -> String {
        value.formatted(
            .number
                .precision(
                    .fractionLength(restriction == .integer ? 0...0 : 0...1)
                )
                .grouping(.never)
        )
    }
}

extension NumberField {
    enum Restriction {
        case integer
        case double
    }
}
