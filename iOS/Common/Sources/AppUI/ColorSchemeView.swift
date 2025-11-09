import Foundation
import SwiftUI
import CommonUI

public struct ColorSchemeView: View {
    @Binding var colorSchemeOverride: ColorSchemeOverride?
    
    public init(colorSchemeOverride: Binding<ColorSchemeOverride?>) {
        self._colorSchemeOverride = colorSchemeOverride
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Appearance")
            
            Picker("", selection: $colorSchemeOverride) {
                Text("Light").tag(ColorSchemeOverride.light)
                Text("Dark").tag(ColorSchemeOverride.dark)
                Text("Default").tag(nil as ColorSchemeOverride?)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
