import Foundation
import SwiftUI
import Auth
import CommonUI
import Backend

public struct SettingsView: View {
    @State var auth = Auth.shared
    @Binding var colorSchemeOverride: ColorSchemeOverride?
    @State var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    
    public init(colorSchemeOverride: Binding<ColorSchemeOverride?>) {
        _colorSchemeOverride = colorSchemeOverride
    }
    
    public var body: some View {
        bodyContent()
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        let marketingVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        
        VStack(alignment: .leading, spacing: 18) {
            if let user = auth.user {
                VStack(alignment: .leading) {
                    Text(user.name)
                        .bold()
                    
                    Text(user.email ?? "")
                    
                    logoutButton()
                }
                
                Divider()
            }
            
            ColorSchemeView(colorSchemeOverride: $colorSchemeOverride)
            
            Divider()
            
            Text("Version: \(marketingVersion)")
        }
        .frame(minWidth: 240)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
        .presentations(ps)
    }
    
    @ViewBuilder
    private func logoutButton() -> some View {
        Button("Log out") {
            ps.presentAlert(title: "Log out?", message: "") {
                Button("Log out") {
                    Task {
                        try await auth.signOut()
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    @Previewable @State var presenting = true
    VStack() {
        HStack {
            Spacer()
            
            Button("", systemImage: "person.fill") {
                presenting = true
            }
            .popover(isPresented: $presenting) {
                SettingsView(colorSchemeOverride: .constant(nil))
            }
        }
        .padding()
        
        Spacer()
    }
}
