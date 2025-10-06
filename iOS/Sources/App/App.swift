import SwiftUI
import SwiftData

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .environment(AppDefaults.shared)
    }
}

private struct ContentView: View {
    @State var userManager = UserManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        bodyContent()
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .active {
                    Task {
                        try await userManager.refreshUser()
                    }
                }
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if userManager.user != nil {
            TabView {
                InventoryView()
                    .tabItem {
                        Label("Inventory", systemImage: "list.bullet.rectangle.portrait")
                    }
                
                ScanLaunchView()
                    .tabItem {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                            .imageScale(.large)
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
