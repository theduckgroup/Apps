import SwiftUI
import Backend

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    Auth.shared.handleOAuthURL(url)
                }
        }
    }
}
