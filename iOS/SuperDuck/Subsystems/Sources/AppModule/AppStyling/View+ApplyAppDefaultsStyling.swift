import Foundation
public import SwiftUI
import Common
import CommonUI

public extension View {
    /// Applies styling from `AppDefaults` environment object (which must be set).
    @ViewBuilder
    func applyAppDefaultsStyling() -> some View {
        modifier(Impl())
    }
}

private struct Impl: ViewModifier {
    @State var uikitContext = UIKitContext()
    @Environment(AppDefaults.self) private var appDefaults
    
    func body(content: Content) -> some View {
        // Notes:
        // - Changing preferredColorScheme does not change already presented views
        // - window.overrideUserInteraceStyle doesn't work perfectly either (e.g. in Home View -> Settings popover on iPad),
        //   but is better than preferredColorScheme
        // - Can't mix preferredColorScheme and window.overrideUserInteraceStyle
        
        // Notes:
        // - `tint` does not work properly (eg the "Log out" button, it does work fine apart from that)
        // - window.tintColor works fine on device but not in previews...
        
        content
            .attach(uikitContext)
            .onFirstAppear {
                applyColorScheme()
            }
            .onChange(of: appDefaults.colorSchemeOverride, applyColorScheme)
            .onChange(of: appDefaults.accentColor, applyColorScheme)
            .modified {
                if isRunningForPreviews {
                    $0.tint(appDefaults.accentColor)
                } else {
                    $0
                }
            }
    }
    
    private func applyColorScheme() {
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
            
            window.tintColor = UIColor(appDefaults.accentColor)
        }
    }
}
