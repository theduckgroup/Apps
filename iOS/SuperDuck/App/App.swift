import SwiftUI
import Backend
import AppShared
import InventoryApp

@main
struct App: SwiftUI.App {
    init() {}
    
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

// Singletons

let auth = Auth()

let api = {
    switch AppInfo.buildTarget {
    case .prod: API(env: .prod, auth: auth)
    case .local: API(env: .local, auth: auth)
    }
}()

let appDefaults = AppDefaults()

let inventoryAppDefaults = InventoryApp.Defaults()
