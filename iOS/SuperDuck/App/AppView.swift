import SwiftUI
import AppShared
import Backend
import CommonUI

struct AppView: View {
    @Environment(Auth.self) var auth
    @Environment(AppDefaults.self) var appDefaults
    @State var uikitContext = UIKitContext()
    
    init() {}
    
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
            .environment(appDefaults)
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
