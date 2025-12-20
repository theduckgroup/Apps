import Foundation
import SwiftUI
import Auth
import CommonUI
import Backend

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
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                userView()
                
                Divider()
                
                themeView()
                
                Divider()
                
                versionView()
            }
            .padding()
            
//                if horizontalSizeClass != .regular {
//                    HStack(alignment: .top, spacing: 36) {
//                        VStack(alignment: .leading, spacing: 18) {
//                            userView()
//                            
//                            Divider()
//                            
//                            //                VStack(alignment: .leading, spacing: 12) {
//                            //                    Text("Theme")
//                            //
//                            //                    if horizontalSizeClass == .regular {
//                            //                        HStack(alignment: .top, spacing: 24) {
//                            //                            ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
//                            //                            AccentColorView(accentColor: $appDefaults.accentColor)
//                            //                        }
//                            //
//                            //                    } else {
//                            //                        VStack(alignment: .leading, spacing: 3) {
//                            //                            ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
//                            //                                .frame(maxWidth: horizontalSizeClass == .regular ? 360 : nil, alignment: .leading)
//                            //
//                            //                            AccentColorView(accentColor: $appDefaults.accentColor)
//                            //                        }
//                            //                    }
//                            //                }
//                            
//                            versionView()
//                        }
//                        
//                        themeView()
//                    }
//                } else {
//                    VStack(alignment: .leading, spacing: 18) {
//                        userView()
//                        
//                        Divider()
//                        
//                        themeView()
//                        
//                        Divider()
//                        
//                        versionView()
//                    }
//                }
//            }
//            .padding()

            Spacer()
        }
    }
    
    @ViewBuilder
    private func userView() -> some View {
        let user = auth.user!
        
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(Color(UIColor.systemGray2))
                .offset(y: -6)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(user.name)
                    .font(.title2)
                    .bold()
                
                Text(user.email ?? "")
                
                logoutButton()
                    .padding(.top, 6)
            }
        }
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
    
    @ViewBuilder
    private func versionView() -> some View {
        let marketingVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        Text("Version: \(marketingVersion)")
    }
    
    @ViewBuilder
    private func themeView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")

            ColorSchemeView(colorSchemeOverride: $appDefaults.colorSchemeOverride)
                .frame(maxWidth: horizontalSizeClass == .regular ? 390 : nil, alignment: .leading)
            
            AccentColorView(accentColor: $appDefaults.accentColor)
                .padding(.top, 3)
        }
    }
}
