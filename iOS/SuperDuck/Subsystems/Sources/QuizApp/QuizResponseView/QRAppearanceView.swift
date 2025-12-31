import Foundation
import SwiftUI
import AppModule
import CommonUI

struct QRAppearanceView: View {
    @Binding var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    
    init(dynamicTypeSizeOverride: Binding<DynamicTypeSizeOverride?>) {
        _dynamicTypeSizeOverride = dynamicTypeSizeOverride
    }
    
    var body: some View {
        @Bindable var appDefaults = appDefaults

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Theme")
                ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
            }
            
            Divider()
            
            textSizeView()
        }
        .frame(width: 320)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
        .preferredColorScheme(appDefaults.colorSchemeOverride?.colorScheme)
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
            .disabled(dynamicTypeSizeOverride == nil || dynamicTypeSizeOverride?.dynamicTypeSize == systemDynamicTypeSize)
        }
    }
}
