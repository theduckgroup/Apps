import Foundation
import SwiftUI
import CommonUI

struct AppView: View {
    @State var auth = Auth.shared
    @Environment(AppDefaults.self) var appDefaults
    
    var body: some View {
        bodyContent()
            .tint(.red)
            .onAppear {
                applyStylingOverride()
            }
            .onChange(of: appDefaults.colorSchemeOverride) {
                applyStylingOverride()
            }
    }
    
    private func applyStylingOverride() {
        let window = UIApplication.shared.anyKeyWindow
        
        window?.overrideUserInterfaceStyle = switch appDefaults.colorSchemeOverride {
        case .light: .light
        case .dark: .dark
        case .none: .unspecified
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
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AppView()
        .environment(AppDefaults())
}
