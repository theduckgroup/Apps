import Foundation
import SwiftUI

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
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        
        guard let window = scene?.keyWindow else {
            return
        }
        
        if let override = appDefaults.colorSchemeOverride {
            window.overrideUserInterfaceStyle = switch override {
            case .light: .light
            case .dark: .dark
            }
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
        }
    }
}

#Preview {
    AppView()
}
