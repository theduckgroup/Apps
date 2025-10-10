import SwiftUI
import SwiftData

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    Auth.shared.handleOAuthURL(url)
                }
                .environment(AppDefaults())
        }
    }
}
