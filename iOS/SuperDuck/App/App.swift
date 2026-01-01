import SwiftUI
import Backend
import AppModule
import InventoryApp

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    auth.handle(url)
                }
        }
        .environment(auth)
        .environment(api)
        .environment(AppDefaults())
        .environment(InventoryAppDefaults())
    }
}

private let auth = Auth()

private let api = {
    switch AppInfo.buildTarget {
    case .prod: API(env: .prod, auth: auth)
    case .local: API(env: .local, auth: auth)
    }
}()
