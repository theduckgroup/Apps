import Foundation
import SwiftUI
import Auth
import Backend

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
            if let user = auth.user {
                HStack(alignment: .firstTextBaseline) {
//                    Image(systemName: "person.fill")
//                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .bold()
                        
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
            }
            
            ColorSchemeView()
            
            Divider()
            
            Text("Version: \(AppInfo.marketingVersion) (\(AppInfo.bundleVersion))")
        }
        .frame(minWidth: 240)
        .padding(.horizontal, 27)
        .padding(.vertical, 24)
        .presentationCompactAdaptation(.popover)
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
                SettingsView()
            }
        }
        .padding()
        
        Spacer()
    }
    .environment(AppDefaults())
}
