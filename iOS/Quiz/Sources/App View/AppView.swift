import Foundation
import SwiftUI
import CommonUI
import AppUI
import Backend

struct AppView: View {
    @State var auth = Auth.shared
    @Environment(AppDefaults.self) var appDefaults
    
    var body: some View {
        bodyContent()
            // .tint(.red)
            .onFirstAppear {
                _ = KeyboardDoneButtonManager.shared
                applyStylingOverride()
            }
            .onChange(of: appDefaults.colorSchemeOverride) {
                applyStylingOverride()
            }
            .onChange(of: appDefaults.accentColor) {
                applyStylingOverride()
            }
    }
    
    private func applyStylingOverride() {
        let window = UIApplication.shared.anyKeyWindow
        
        guard let window else {
            assertionFailure()
            return
        }
        
        window.overrideUserInterfaceStyle = switch appDefaults.colorSchemeOverride {
        case .light: .light
        case .dark: .dark
        case .none: .unspecified
        }
        
        window.tintColor = UIColor(appDefaults.accentColor)
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
