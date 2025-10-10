import Foundation
import SwiftUI

struct SettingsView: View {
    @State var auth = Auth.shared
    @State var presentingLogoutAlert = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    
    init() {}
    
    var body: some View {
        bodyContent()
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ColorSchemeView()
            
            if let user = auth.user {
                Divider()
                
                VStack(alignment: .leading) {
                    Text(user.email ?? "")
                    
                    Button("Log out") {
                        presentingLogoutAlert = true
                    }
                    .buttonStyle(.borderless)
                    .alert("Log out?", isPresented: $presentingLogoutAlert) {
                        Button("Log out") {
                            Task {
                                try await auth.signOut()
                            }
                        }
                        
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            
            Divider()
            
            Text("Version: \(AppInfo.marketingVersion) (\(AppInfo.bundleVersion))")
        }
        .frame(width: 240)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    VStack() {
        HStack {
            Spacer()
            
            Button("", systemImage: "square.and.arrow.up") {
                
            }
            .popover(isPresented: .constant(true)) {
                SettingsView()
            }
        }
        .padding()
        
        Spacer()
    }
    .environment(AppDefaults())
}
