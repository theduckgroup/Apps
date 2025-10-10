import Foundation
import SwiftUI

struct QuizAppearanceView: View {
    @Binding var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ColorSchemeView()
            Divider()
            textSizeView()
        }
        .frame(width: 240)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
    }
    
    @ViewBuilder
    private func textSizeView() -> some View {
        VStack(alignment: .leading) {
            Text("Text Size")
            
            let values = DynamicTypeSizeOverride.allCases
            let enumerated = values.enumerated()
            let map: [Int: DynamicTypeSizeOverride] = .init(uniqueKeysWithValues: enumerated.map { ($0, $1) })
            let reverseMap: [DynamicTypeSizeOverride: Int] = .init(uniqueKeysWithValues: enumerated.map { ($1, $0) })
            let keys = map.keys.sorted()
            let minValue = keys.first!
            let maxValue = keys.last!
            
            let valueBinding = Binding<Double> {
                let value = dynamicTypeSizeOverride ?? .init(from: systemDynamicTypeSize) ?? .large
                return Double(reverseMap[value] ?? keys.last!)
            } set: {
                let value = map[Int($0.rounded())]!
                dynamicTypeSizeOverride = value
            }
            
            Slider(
                value: valueBinding,
                in: Double(minValue)...Double(maxValue),
                step: 1,
                label: { Text("Font Size") },
                minimumValueLabel: { },
                maximumValueLabel: { }
            )
            
            Button("Reset Default") {
                dynamicTypeSizeOverride = nil
            }
            .padding(.top, 6)
        }
    }
}
