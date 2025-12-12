import Foundation
import SwiftUI
import CommonUI
import AppUI
import Backend

struct AppView: View {
    var auth = Auth.shared
    @Environment(AppDefaults.self) var appDefaults
    
    var body: some View {
        bodyContent()
            .tint(appDefaults.accentColor)
            .preferredColorScheme(appDefaults.colorSchemeOverride?.colorScheme)
            .onFirstAppear {
                _ = KeyboardDoneButtonManager.shared
            }
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
                .scaleEffect(1.5)
                .tint(.secondary)
        }
    }
}

#Preview {
    AppView()
        .environment(AppDefaults())
}
