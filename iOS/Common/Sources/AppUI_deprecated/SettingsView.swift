import Foundation
import SwiftUI
import Auth
import CommonUI
import Backend_deprecated

public struct SettingsView: View {
    @State var auth = Auth.shared
    @Binding var colorSchemeOverride: ColorSchemeOverride?
    @Binding  var accentColor: Color
    let containerHorizontalSizeClass: UserInterfaceSizeClass?
    @State private var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    
    public init(
        colorSchemeOverride: Binding<ColorSchemeOverride?>,
        accentColor: Binding<Color>,
        containerHorizontalSizeClass: UserInterfaceSizeClass?
    ) {
        self._colorSchemeOverride = colorSchemeOverride
        self._accentColor = accentColor
        self.containerHorizontalSizeClass = containerHorizontalSizeClass
    }
    
    public var body: some View {
        Group {
            if containerHorizontalSizeClass == .compact {
                NavigationStack {
                    bodyContent()
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                }
                
            } else {
                bodyContent()
                    .padding(12)
            }
        }
        // .presentationCompactAdaptation(.popover)
        .presentations(ps)        
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let user = auth.user {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.title2)
                            .bold()
                        
                        Text(user.email ?? "")
                        
                        logoutButton()
                            .padding(.top, 6)
                    }
                    
                    Divider()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")

                    ColorSchemeView(colorSchemeOverride: $colorSchemeOverride)
                    
                    AccentColorView(accentColor: $accentColor)
                        .padding(.top, 3)
                }
                
                Divider()
                
                let marketingVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                Text("Version: \(marketingVersion)")
            }
            .padding()
        }
        .frame(width: containerHorizontalSizeClass == .regular ? 400 : nil)
    }
    
    @ViewBuilder
    private func logoutButton() -> some View {
        Button("Log out") {
            ps.presentAlert(title: "Log out?", message: "") {
                Button("Log out") {
                    Task {
                        try await auth.signOut()
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    PreviewView()
}

private struct PreviewView: View {
    @State var presenting = true
    @State var accentColor: Color = .theme
    @State var colorSchemeOverride: ColorSchemeOverride?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
          VStack() {
              HStack {
                  Spacer()
                  
                  Button("", systemImage: "person.fill") {
                      presenting = true
                  }
                  .padding(6)
                  .popover(isPresented: $presenting) {
                      SettingsView(
                        colorSchemeOverride: $colorSchemeOverride,
                        accentColor: $accentColor,
                        containerHorizontalSizeClass: horizontalSizeClass
                      )
                  }
              }
              .padding()
              
              Spacer()
          }
          .tint(accentColor)
          .preferredColorScheme(colorSchemeOverride?.colorScheme)
    }
}
