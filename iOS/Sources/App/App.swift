import SwiftUI
import SwiftData

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Auth.shared.handleOAuthURL(url)
                }
        }
        .environment(AppDefaults.shared)
    }
}

private struct ContentView: View {
    @State var auth = Auth.shared
    
    var body: some View {
        bodyContent()
            .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if auth.user != nil {
            HomeView()
            
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
