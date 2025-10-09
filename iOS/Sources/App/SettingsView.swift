import Foundation
import SwiftUI

struct SettingsView: View {
    @State var auth = Auth.shared
    @State var presentingConfirmResetDataAlert = false
    @State var presentingConfirmLogoutAlert = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    
    init() {}
    
    var body: some View {
        NavigationStack {
            List {
                bodyContent()
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if let user = auth.user {
            Section("Account") {
                HStack(alignment: .center) {
//                    Image(systemName: "person.circle")
//                        // .symbolVariant(.fill)
//                        .imageScale(.large)
//                        .font(.system(size: 48, weight: .thin))
//                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text("(Name)")
                            .font(.title)
                        
                        Text("(Email)")
                    }
                }
                
                Button("Log out") {
                    presentingConfirmLogoutAlert = true
                }
                .buttonStyle(.borderless)
                .alert("Log out?", isPresented: $presentingConfirmLogoutAlert) {
                    Button("Log out") {
                        Task {
                            try await auth.signOut()
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        
        Section("App Info") {
//            Button("Reset Data") {
//                presentingConfirmResetDataAlert = true
//            }
//            .alert("Reset Data?", isPresented: $presentingConfirmResetDataAlert) {
//                Button("Reset", role: .destructive) {
//                    userManager.resetData()
//                }
//                
//                Button("Cancel", role: .cancel) {}
//            }
            
            Text("Version: \(AppInfo.bundleVersion)")
        }
    }
}


#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AppDefaults.shared)
}
