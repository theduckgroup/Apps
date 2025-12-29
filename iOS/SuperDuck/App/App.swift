import SwiftUI
import Backend
import AppShared

@main
struct App: SwiftUI.App {
    let auth: Auth
    let api: API
    let appDefaults = AppDefaults(storageKey: "appDefaults:v2")
    
    init() {
        let auth = Auth()
        
        self.auth = auth
        
        self.api = {
            switch AppInfo.buildTarget {
            case .prod: API(env: .prod, auth: auth)
            case .local: API(env: .local, auth: auth)
            }
        }()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    auth.handle(url)
                }
        }
        .environment(auth)
        .environment(api)
        .environment(appDefaults)
    }
}
