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
        }
        .environment(AppDefaults.shared)
    }
}

private struct AppView: View {
    @State var auth = Auth.shared
    
    var body: some View {
        bodyContent()
            .preferredColorScheme(.light)
            .tint(.red)
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if auth.isLoaded {
            if auth.user != nil {
                HomeView()
                
            } else {
                LoginView()
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
}

#Preview {
    AppView()
}
