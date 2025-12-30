import Foundation
public import SwiftUI

public struct QuantityField: View {
    @Binding var value: Double
    var unit: String? = nil

    public init(value: Binding<Double>, unit: String? = nil) {
        self._value = value
        self.unit = unit
    }

    public var body: some View {
        HStack(spacing: 12) {
            Button {
                if value > 0 {
                    value -= 1
                }
            } label: {
                Image(systemName: "minus.circle.fill")
            }
            .disabled(value <= 0)

            NumberField(value: $value, unit: unit, fractionLength: 0)
                .padding(.vertical, 9)
                .padding(.horizontal, 18)
                .background {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(UIColor.tertiarySystemFill))
                }
//                .background(alignment: .bottom) {
//                    Rectangle()
//                        .fill(Color(UIColor.separator))
//                        .frame(height: 1)
//                }

            Button {
                value += 1
            } label: {
                Image(systemName: "plus.circle.fill")
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
