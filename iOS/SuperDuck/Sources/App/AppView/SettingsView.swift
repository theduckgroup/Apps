import Foundation
import SwiftUI
import CommonUI
import Auth

/// Settings view.
///
/// Use `TabView` to preview.
struct SettingsView: View {
    @State private var ps = PresentationState()
    @State private var presentingBarcodeScannerSettings = false
    @Environment(Auth.self) var auth
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public var body: some View {
        NavigationStack {
            bodyContent()
                .presentations(ps)
                .toolbar { toolbarContent() }
                .navigationDestination(isPresented: $presentingBarcodeScannerSettings) {
                    BarcodeScannerSettingsView()
                        .floatingTabBarSafeAreaInset()
                }
                .navigationTitle("Settings")
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Log out") {
                ps.presentAlert(title: "Log out?", message: "") {
                    Button("Log out", role: .destructive) {
                        Task {
                            try await auth.signOut()
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }
            }
            .buttonStyle(.automatic)
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
            
            Section("App Visibility") {
                tabViewItemsView()
            }
            
            Section("Advanced Settings") {
                Button("QR Code Scanner") {
                    presentingBarcodeScannerSettings = true
                }
            }
            
            Section("Version") {
                versionView()
            }
        }
        .nonProdEnvWarningOverlay()
        .floatingTabBarSafeAreaInset()
    }
    
    @ViewBuilder
    private func userView() -> some View {
        if let user = auth.user {
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.title3)
                    .bold()
                
                Text(user.email ?? "")
            }
        }
    }
    
    @ViewBuilder
    private func versionView() -> some View {
        let appName = switch AppInfo.buildTarget {
        case .prod: "Super Duck"
        case .prodAdhoc: "Super Duck (Internal)"
        case .local: "Super Duck (Local)"
        }
        
        Text("\(appName) \(AppInfo.marketingVersion)")
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
    
    @ViewBuilder
    private func tabViewItemsView() -> some View {
        let tabViewItems = TabViewItem.allCases.filter { $0 != .settings }
        
        ForEach(tabViewItems, id: \.self) { item in
            let binding = Binding<Bool> {
                !appDefaults.hiddenTabViewItems.contains(item)
                
            } set: { newValue in
                let set = Set(appDefaults.hiddenTabViewItems)
                
                if newValue {
                    appDefaults.hiddenTabViewItems = Array(set.subtracting([item]))
                } else {
                    appDefaults.hiddenTabViewItems = Array(set.union([item]))
                }
            }
            
            Toggle(isOn: binding, label: { Text(item.name) })
        }
    }
}

#Preview {
    SettingsView()
        .applyAppDefaultsStyling()
        .previewEnvironment()        
}
