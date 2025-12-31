import Foundation
public import SwiftUI

public struct NumberField: View {
    @Binding var value: Double
    var unit: String? = nil
    var fractionLengthLimits: ClosedRange<Int> = 0...2
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    public init(value: Binding<Double>, unit: String? = nil, fractionLengthLimits: ClosedRange<Int>) {
        precondition(fractionLengthLimits.lowerBound >= 0)
        self._value = value
        self.unit = unit
        self.fractionLengthLimits = fractionLengthLimits
        self.text = text
        self.isFocused = isFocused
    }
    
    public init(value: Binding<Double>, unit: String? = nil, fractionLength: Int) {
        self.init(value: value, unit: unit, fractionLengthLimits: fractionLength...fractionLength)
    }

    public var body: some View {
        TextField("", text: $text)
            .keyboardType(fractionLengthLimits.upperBound == 0 ? .numberPad : .decimalPad)
            .focused($isFocused)
            .onChange(of: text) { _, text in
                if let parsedValue = Double(text) {
                    value = parsedValue.rounded(toPlaces: fractionLengthLimits.upperBound)
                } else if text.isEmpty {
                    value = 0
                } else {
                    // Leave it alone
                    // If user enters a valid number at some point, it will be used
                    // Otherwise the field reverts to old value after losing focus
                }
            }
            .onChange(of: value) { _, value in
                if !isFocused {
                    text = formatValue(value)
                }
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    // Format for editting
                    text = value != 0 ? value.formatted(.number.grouping(.never)) : ""
                    
                } else {
                    // Format for display
                    text = formatValue(value)
                }
            }
            .onFirstAppear {
                text = formatValue(value)
            }
    }
    
    private func formatValue(_ value: Double) -> String {
        let formattedValue = value.formatted(.number.precision(.fractionLength(fractionLengthLimits)))
        
        if let unit {
            return "\(formattedValue) \(unit)"
        } else {
            return formattedValue
        }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = Double.pow(10, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

#Preview {
    @Previewable @State var value: Double = 100.02
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: 18) {
        Text("Value: \(value)")

        // NumberField(value: $value)
        // NumberField(value: $value, unit: "kg")
        NumberField(value: $value, unit: "kg", fractionLength: 0)
        // NumberField(value: $value, unit: "kg", fractionLength: 1)
        // NumberField(value: $value, unit: "mph", fractionLengthLimits: 0...2)
            .multilineTextAlignment(.center)
            .font(.system(size: 24))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(width: 250)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.separator, lineWidth: 1)
            }
            .focused($isFocused)

        HStack {
            Button("Unfocus") {
                isFocused = false
            }
            
            Button("Set") {
                value = Double.random(in: 0...1000)
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}

