import Foundation
import SwiftUI

struct AppearanceView: View {
    @Environment(AppDefaults.self) var appDefaults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            colorSchemeView()
        }
        .frame(width: 240)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
    }
    
    @ViewBuilder
    private func colorSchemeView() -> some View {
        @Bindable var appDefaults = appDefaults
        
        VStack(alignment: .leading, spacing: 9) {
            Text("Color Scheme")
            
            Picker("", selection: $appDefaults.colorSchemeOverride) {
                Text("Light").tag(ColorSchemeOverride.light)
                Text("Dark").tag(ColorSchemeOverride.dark)
                Text("System").tag(nil as ColorSchemeOverride?)
            }
            .pickerStyle(.segmented)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    @Previewable @State var presenting = true
    
    VStack() {
        HStack {
            Spacer()
            
            Button("Appearance") {
                presenting = true
            }
            .popover(isPresented: $presenting) {
                AppearanceView()
            }
        }
        .padding()
        
        Spacer()
    }
    .environment(AppDefaults())
}
