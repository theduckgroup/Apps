import Foundation
import SwiftUI

public extension View {
    /// Presents an alert cover.
    ///
    /// This is similar to `alert` but accepts SwiftUI view as content.
    ///
    /// The alert's content has subheadline font and center text alignment by default. If you build
    /// complex content, use headline font for title and subheadline font for body to match iOS styling.
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - isPresented: The alert is presented when this is set to `true`.
    ///   - actions: The alert actions. Default is a "OK" action.
    ///   - content: The alert content.
    @ViewBuilder
    func alertCover<Content: View>(
        _ title: String = "",
        isPresented: Binding<Bool>,
        actions: [AlertCoverAction] = [.ok],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AlertCoverModifier(title: title, isPresented: isPresented, actions: actions, content: content))
    }
}

public extension PresentationState {
    /// Presents an alert with custom content.
    func presentAlertCover<C: View>(title: String, actions: [AlertCoverAction], @ViewBuilder content: @escaping () -> C) {
        present { hostView, $isPresented in
            hostView.alertCover(title, isPresented: $isPresented, actions: actions, content: content)
        }
    }
}

/// An action for `alertCover`.
public struct AlertCoverAction {
    public var title: String
    public var handler: @MainActor () -> Void
    
    public init(title: String, handler: @escaping @MainActor () -> Void) {
        self.title = title
        self.handler = handler
    }
    
    public static let ok = AlertCoverAction(title: "OK", handler: {})
}

private struct AlertCoverModifier<C: View>: ViewModifier {
    let title: String
    @Binding var isPresented: Bool
    let actions: [AlertCoverAction]
    let content: () -> C
    @State private var uikitContext = UIKitContext()
    
    func body(content: Content) -> some View {
        content
            .uikitContext(uikitContext)
            .onFirstAppear {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: alertContent())
                    uikitContext.present(controller, animated: false)
                }
            }
            .onChange(of: isPresented) {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: alertContent())
                    uikitContext.present(controller, animated: true)
                    
                } else {
                    uikitContext.dismiss(animated: true)
                }
            }
    }
    
    @ViewBuilder
    private func alertContent() -> some View {
        VStack(spacing: 0) {
            let hasTitle = !title.isEmpty
            
            if hasTitle {
                Text(title)
                    .font(.body)
                    .bold()
                    .padding(.top)
            }
            
            content()
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding([.horizontal, .bottom])
                .padding(.top, hasTitle ? 9 : nil)
            
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                Button {
                    isPresented = false
                    action.handler()
                    
                } label: {
                    Text(action.title)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .overlay(alignment: .top) { Divider() }
            }
        }
        .frame(minWidth: 240, maxWidth: 320)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    @Previewable @State var presentingAlert = false
    
    Button("Present") {
        presentingAlert = true
    }
    .alertCover(
        "Et tempor",
        isPresented: $presentingAlert,
        actions: [
            .init(title: "OK", handler: {}),
            .init(title: "Ahaha", handler: { print("Ahaha!") })
        ]
    ) {
        VStack {
            Text("Tempor sit ad ad excepteur deserunt nulla consequat sit. Aliquip veniam voluptate cillum sunt ea.")
            Text("[A link](https://makemerich.com)")
        }
    }
}
