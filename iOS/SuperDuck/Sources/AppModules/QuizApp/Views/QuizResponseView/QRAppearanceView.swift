import Foundation
import SwiftUI
import CommonUI

struct QRAppearanceView: View {
    @Environment(QuizAppDefaults.self) var defaults
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    var body: some View {
        @Bindable var defaults = defaults

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Theme")
                ColorSchemeView(colorSchemeOverride: $defaults.colorSchemeOverride)
            }

            Divider()

            textSizeView()
        }
        .frame(width: 320)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
        .preferredColorScheme(defaults.colorSchemeOverride?.colorScheme)
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
                let value = defaults.dynamicTypeSizeOverride ?? .init(from: systemDynamicTypeSize) ?? .large
                return Double(reverseMap[value] ?? keys.last!)
            } set: {
                let value = map[Int($0.rounded())]!
                defaults.dynamicTypeSizeOverride = value
            }

            Slider(
                value: valueBinding,
                in: Double(minValue)...Double(maxValue),
                step: 1,
                label: { Text("Font Size") },
                minimumValueLabel: { },
                maximumValueLabel: { }
            )

            Button("Reset to Default") {
                defaults.dynamicTypeSizeOverride = nil
            }
            .padding(.top, 6)
            .disabled(defaults.dynamicTypeSizeOverride == nil || defaults.dynamicTypeSizeOverride?.dynamicTypeSize == systemDynamicTypeSize)
        }
    }
}
