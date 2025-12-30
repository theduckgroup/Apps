import Foundation
import SwiftUI

public extension View {
    /// Presents an alert cover.
    @ViewBuilder
    func smallSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(SmallSheetModifier(isPresented: isPresented, content: content))
    }
}

public extension PresentationState {
    func presentSmallSheet<C: View>(@ViewBuilder content: @escaping () -> C) {
        present { hostView, $isPresented in
            hostView.smallSheet(isPresented: $isPresented, content: content)
        }
    }
}

private struct SmallSheetModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> C
    @State private var uikitContext = UIKitContext()
    
    func body(content: Content) -> some View {
        content
            .attach(uikitContext)
            .onFirstAppear {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: self.content())
                    uikitContext.present(controller, animated: false)
                }
            }
            .onChange(of: isPresented) {
                if isPresented {
                    let controller = AlertTransitioningHostingController(rootView: self.content())
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
    .smallSheet(isPresented: $presenting) {
        VStack {
            Text("Tempor sit ad ad excepteur deserunt nulla consequat sit. Aliquip veniam voluptate cillum sunt ea.")
            Text("[A link](https://makemerich.com)")
        }
        .padding()
        .frame(maxWidth: 280)
    }
}
