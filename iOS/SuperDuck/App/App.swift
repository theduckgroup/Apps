import SwiftUI
import Backend
import AppModule
import InventoryApp
import QuizApp

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
        .environment(QuizAppDefaults())
    }
}

private let auth = Auth()

private let api = {
    switch AppInfo.buildTarget {
    case .prod, .prodAdhoc: API(env: .prod, auth: auth)
    case .local: API(env: .local, auth: auth)
    }
}()
