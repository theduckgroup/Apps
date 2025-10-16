import Foundation
import SwiftUI

struct ColorSchemeView: View {
    @Environment(AppDefaults.self) var appDefaults
    
    var body: some View {
        @Bindable var appDefaults = appDefaults
        
        VStack(alignment: .leading, spacing: 9) {
            Text("Color Scheme")
            
            Picker("", selection: $appDefaults.colorSchemeOverride) {
                Text("Light").tag(ColorSchemeOverride.light)
                Text("Dark").tag(ColorSchemeOverride.dark)
                Text("System").tag(nil as ColorSchemeOverride?)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
