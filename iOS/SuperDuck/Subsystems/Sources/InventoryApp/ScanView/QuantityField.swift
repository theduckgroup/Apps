import Foundation
public import SwiftUI
import CommonUI

public struct QuantityField: View {
    @Binding var value: Double
    @FocusState var isFocused: Bool
    var unit: String? = nil
    @ScaledMetric var numberFieldWidth: CGFloat = 39

    public init(value: Binding<Double>, unit: String? = nil) {
        self._value = value
        self.unit = unit
    }

    public var body: some View {
        HStack(spacing: 12) {
            Button {
                if value > 0 {
                    value -= 1
                    isFocused = false                    
                }
            } label: {
                Image(systemName: "minus.circle")
            }
            .disabled(value <= 0)

            NumberField(value: $value, unit: unit, fractionLength: 0)
                .focused($isFocused)
                .frame(width: numberFieldWidth)
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .background {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(UIColor.tertiarySystemFill))
                }

            Button {
                value += 1
                isFocused = false
            } label: {
                Image(systemName: "plus.circle")
            }
        }
        .imageScale(.large)
    }
}

#Preview {
    @Previewable @State var value: Double = 5

    VStack(spacing: 18) {
        Text("Value: \(Int(value))")
        QuantityField(value: $value, unit: "items")
        QuantityField(value: $value)
    }
    .fixedSize()
    .multilineTextAlignment(.center)
    .padding()
    .tint(Color.mantineTeal)
    .preferredColorScheme(.dark)
}
