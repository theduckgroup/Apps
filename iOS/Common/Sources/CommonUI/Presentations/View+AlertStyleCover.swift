import Foundation
import SwiftUI

public extension View {
    /// Presents an alert cover.
    @ViewBuilder
    func alertStyleCover<Content: View>(
        isPresented: Binding<Bool>,
        offset: CGPoint = .zero,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AlertStyleCoverModifier(isPresented: isPresented, offset: offset, content: content))
    }
}

public extension PresentationState {
    func presentAlertStyleCover<C: View>(offset: CGPoint = .zero, @ViewBuilder content: @escaping () -> C) {
        present { hostView, $isPresented in
            hostView.alertStyleCover(isPresented: $isPresented, offset: offset, content: content)
        }
    }
}

private struct AlertStyleCoverModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let offset: CGPoint
    let content: () -> C
    @State private var uikitContext = UIKitContext()
    
    func body(content: Content) -> some View {
        content
            .attach(uikitContext)
            .onFirstAppear {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: self.content(), offset: offset)
                    uikitContext.present(controller, animated: false)
                }
            }
            .onChange(of: isPresented) {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: self.content(), offset: offset)
                    uikitContext.present(controller, animated: true)
                    
                } else {
                    uikitContext.dismiss(animated: true)
                }
            }
    }
}

#Preview {
    @Previewable @State var presenting = false
    
    Button("Present") {
        presenting = true
    }
    .alertStyleCover(isPresented: $presenting, offset: .init(x: 0, y: -30)) {
        VStack {
            Text("Tempor sit ad ad excepteur deserunt nulla consequat sit. Aliquip veniam voluptate cillum sunt ea.")
            Text("[A link](https://makemerich.com)")
        }
        .padding()
        .frame(maxWidth: 280)
    }
}
