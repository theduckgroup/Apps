import SwiftUI
import AppShared
import Backend
import CommonUI

struct AppView: View {
    @Environment(Auth.self) var auth
    
    init() {}
    
    var body: some View {
        bodyContent()
            .applyAppDefaultsStyling()
            .onFirstAppear {
                _ = KeyboardDoneButtonManager.shared
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if auth.isLoaded {
            if auth.user != nil {
                TabView()
                
            } else {
                LoginView()
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.secondary)
        }
    }
}

#Preview {
    AppView()
        .previewEnvironment()
}
