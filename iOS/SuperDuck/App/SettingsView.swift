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
    @State private var ps = PresentationState()
    @Environment(Auth.self) var auth
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Settings")
                .presentations(ps)
                .toolbar { toolbarContent() }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
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
        .nonProdEnvWarningOverlay()
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
        Text(AppInfo.marketingVersion)
    }
    
    @ViewBuilder
    private func themeView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            @Bindable var appDefaults = appDefaults
            
            ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
                .frame(maxWidth: horizontalSizeClass == .regular ? 390 : nil, alignment: .leading)
            
            AccentColorView(accentColor: $appDefaults.accentColor)
                .padding(.top, 3)
        }
    }
}

#Preview {
    SettingsView()
        .applyAppDefaultsStyling()
        .previewEnvironment()        
}
