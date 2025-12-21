import Foundation
import SwiftUI
import AppShared
import Auth
import Backend
import CommonUI

/// Settings view.
///
/// Use `TabView` to preview.
struct SettingsView: View {
    private var auth = Auth.shared
    @Bindable private var appDefaults = AppDefaults.shared
    @State private var ps = PresentationState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Settings")
                .presentations(ps)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
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
                        .buttonStyle(.borderedProminent)
                    }
                }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        Form {
            Section("Account") {
                userView()
            }
            
            Section("Theme") {
                themeView()
            }
            
            Section("Version") {
                versionView()
            }
        }
    }
    
    @ViewBuilder
    private func userView() -> some View {
        if let user = auth.user {
            
            // HStack(alignment: .top, spacing: 15) {
            //            Image(systemName: "person.crop.circle.fill")
            //                .font(.system(size: 56, weight: .thin))
            //                .foregroundStyle(Color(UIColor.systemGray2))
            //                .offset(y: -6)
            //
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.title3)
                    .bold()
                
                Text(user.email ?? "")
            }
            // }
        }
    }

    @ViewBuilder
    private func versionView() -> some View {
        let marketingVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        Text(marketingVersion)
    }
    
    @ViewBuilder
    private func themeView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
                .frame(maxWidth: horizontalSizeClass == .regular ? 390 : nil, alignment: .leading)
            
            AccentColorView(accentColor: $appDefaults.accentColor)
                .padding(.top, 3)
        }
    }
}
