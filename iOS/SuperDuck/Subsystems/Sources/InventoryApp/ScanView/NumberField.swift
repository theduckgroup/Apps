import Foundation
import SwiftUI

struct NumberField: View {
    @Binding var value: Double
    var unit: String? = nil
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: text) { _, newText in
                if let parsedValue = Double(newText) {
                    value = parsedValue
                } else if newText.isEmpty {
                    value = 0
                }
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    // When gaining focus - remove unit and grouping
                    if value == 0 {
                        text = ""
                    } else {
                        // Remove thousand grouping for easy editing
                        text = value.formatted(.number.grouping(.never))
                    }
                } else {
                    // When losing focus - format the display with unit
                    if let parsedValue = Double(text) {
                        text = formatWithUnit(parsedValue.formatted(.number))
                    } else {
                        value = 0
                        text = formatWithUnit("0")
                    }
                }
            }
            .onAppear {
                // Initialize text with formatted value and unit
                let formattedValue = value == 0 ? "0" : value.formatted(.number)
                text = formatWithUnit(formattedValue)
            }
    }
    
    private func formatWithUnit(_ formattedValue: String) -> String {
        if let unit {
            return "\(formattedValue) \(unit)"
        } else {
            return formattedValue
        }
    }
}

#Preview {
    @Previewable @State var value: Double = 1234.56
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: 18) {
        Text("Value: \(value)")

        // NumberField(value: $value, unit: "kg")
        NumberField(value: $value)
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

        Button("Unfocus") {
            isFocused = false
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}
