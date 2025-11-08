import SwiftUI
import Common

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            if debugging {
                let _ = print("Debugging: \(debugging)")
            }
            AppView()
        }
    }
}
