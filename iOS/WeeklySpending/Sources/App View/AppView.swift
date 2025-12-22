import Foundation
import SwiftUI
import CommonUI
import AppUI_deprecated
import Backend_deprecated

struct AppView: View {
    @State var auth = Auth.shared
    @Environment(AppDefaults.self) var appDefaults
    @State private var uikitContext = UIKitContext()
    
    var body: some View {
        // Note:
        // - Changing preferredColorScheme does not change already presented views
        // - window.overrideUserInteraceStyle doesn't work perfectly either (e.g. in Home View -> Settings popover on iPad) but better than preferredColorScheme
        // - Can't mix preferredColorScheme and window.overrideUserInteraceStyle
        // - `tint` works fine

        bodyContent()
            .tint(appDefaults.accentColor)
            .onFirstAppear {
                _ = KeyboardDoneButtonManager.shared
                applyStylingOverride()
            }
            .onChange(of: appDefaults.colorSchemeOverride, applyStylingOverride)
            .attach(uikitContext)
    }
    
    private func applyStylingOverride() {
        uikitContext.onAddedToWindow {
            guard let window = uikitContext.viewController.view.window else {
                assertionFailure()
                return
            }
            
            window.overrideUserInterfaceStyle = switch appDefaults.colorSchemeOverride {
            case .light: .light
            case .dark: .dark
            case .none: .unspecified
            }
        }
    }

    @ViewBuilder
    private func bodyContent() -> some View {
        if auth.isLoaded {
            if let user = auth.user {
                HomeView(user: user)                
            } else {
                LoginView()
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(.secondary)
        }
    }
}

#Preview {
    AppView()
        .environment(AppDefaults())
}
