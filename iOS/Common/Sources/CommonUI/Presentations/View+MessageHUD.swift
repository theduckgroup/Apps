import Foundation
import SwiftUI

public extension View {
    /// Presents a message HUD.
    @ViewBuilder
    func messageHUD(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(MessageHUDModifier(isPresented: isPresented, message: message))
    }
}

public extension PresentationState {
    /// Presents a message HUD and dismisses it after a duration.
    func presentMessageHUD(_ message: String) {
        present { hostView, $isPresented in
            hostView.messageHUD(isPresented: $isPresented, message: message)
        }
    }
}

private struct MessageHUDModifier: ViewModifier {
    var isPresented: Binding<Bool>
    var message: String
    @State private var uikitContext = UIKitContext()
    
    func body(content: Content) -> some View {
        content
            .attach(uikitContext)
            .onFirstAppear {
                if isPresented.wrappedValue {
                    let controller = AlertTransitioningHostingController(rootView: MessageHUDView(message: message))
                    uikitContext.present(controller, animated: false)
                }
            }
            .onChange(of: isPresented.wrappedValue) {
                if isPresented.wrappedValue {
                    let controller = AlertTransitioningHostingController(rootView: MessageHUDView(message: message))
                    uikitContext.present(controller, animated: true)
                    
                } else {
                    uikitContext.dismiss(animated: true)
                }
            }
    }
}

private struct MessageHUDView: View {
    var message: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark")
                .font(.system(size: 21))
                .fontWeight(.medium)
                .imageScale(.large)
            
            Text(message)
        }
        .padding()
        .frame(minWidth: 120)
    }
}

#Preview {
    @Previewable @State var presented = false
    
    VStack(spacing: 24) {
        Button("Present") {
            Task {
                presented = true
                
                try? await Task.sleep(for: .seconds(1))
                
                presented = false
            }
        }
        .messageHUD(isPresented: $presented, message: "Text Copied")
    }
}
