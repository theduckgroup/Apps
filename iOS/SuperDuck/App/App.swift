import SwiftUI
import Backend
import AppShared

@main
struct App: SwiftUI.App {
    let appDefaults = AppDefaults(storageKey: "appDefaults:v2")
    let api = API.shared
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    Auth.shared.handleOAuthURL(url)
                }
        }
        .environment(appDefaults)
        .environment(api)
    }
}
