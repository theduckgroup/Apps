import Foundation
import SwiftUI

public extension View {
    /// Presents a progress HUD.
    ///
    /// The progress HUD is presented if `state` is not `nil`. The state can be used to control its content.
    ///
    /// Example:
    /// ```swift
    /// @State var state = ProgressHUDState(title: "Loading", progress: .determinate(fraction: 0))
    ///
    /// // Present
    /// someView.progressHUD($state)
    ///
    /// // Update state
    /// state.progress = .determinate(fraction: 0.2)
    /// ```
    @ViewBuilder
    func progressHUD(_ state: Binding<ProgressHUDState?>, onDismissComplete: (() -> Void)? = nil) -> some View {
        modifier(ProgressHUDModifier(state: state, onDismissComplete: onDismissComplete))
    }
}

public extension PresentationState {
    /// Presents a progress HUD with state.
    func presentProgressHUD(_ state: ProgressHUDState) {
        present(item: state) { hostView, $state in
            hostView.progressHUD($state)
        }
    }
    
    /// Presents an indeterminate progress HUD.
    func presentProgressHUD(title: String, message: String = "", cancelAction: ProgressHUDState.CancelAction? = nil) {
        let state = ProgressHUDState(title: title, progress: .indeterminate, message: message, cancelAction: cancelAction)
        presentProgressHUD(state)
    }
}

/// Progress HUD state. Use with `View.progressHUD` modifier.
@Observable
public class ProgressHUDState {
    /// Text displayed next to progress view.
    public var title: String
    
    /// Progress.
    public var progress: Progress
    
    /// Text displayed below progress view and title.
    public var message: String
    
    /// Cancel action.
    ///
    /// If not `nil`, a cancel button is shown.
    public var cancelAction: CancelAction?
    
    /// Creates a progress HUD state.
    public init(
        title: String,
        progress: Progress,
        message: String = "",
        cancelAction: CancelAction? = nil
    ) {
        self.title = title
        self.progress = progress
        self.message = message
        self.cancelAction = cancelAction
    }
    
    /// Progress.
    public enum Progress {
        /// Determinate progress with a completed fraction. A circular progress view will be shown.
        case determinate(fraction: Double)

        /// Indeterminate progress. An activity indicator (aka spinner) will be shown.
        case indeterminate        
    }
    
    /// Cancel button.
    public struct CancelAction {
        public var title: String
        public var handler: () -> Void

        public init(title: String, handler: @escaping () -> Void) {
            self.title = title
            self.handler = handler
        }
    }
}

private struct ProgressHUDModifier: ViewModifier {
    let state: Binding<ProgressHUDState?>
    var onDismissComplete: (() -> Void)?
    @State private var uikitContext = UIKitContext()
    
    func body(content: Content) -> some View {
        content
            .uikitContext(uikitContext)
            .onFirstAppear {
                if let state = state.wrappedValue {
                    let controller = AlertTransitioningHostingController(rootView: ProgressHUDView(state: state))
                    uikitContext.present(controller, animated: false)
                }
            }
            .onChange(of: state.wrappedValue != nil) {
                if let state = state.wrappedValue {
                    let controller = AlertTransitioningHostingController(rootView: ProgressHUDView(state: state))
                    uikitContext.present(controller, animated: true)
                    
                } else {
                    uikitContext.dismiss(animated: true, completion: onDismissComplete)
                }
            }
    }
}

private struct ProgressHUDView: View {
    var state: ProgressHUDState
    @ScaledMetric var progressViewSize: CGFloat = 33
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                Group {
                    switch state.progress {
                    case .indeterminate:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.75)
                        
                    case .determinate(_):
                        Text("TODO")
                        // CircularProgressView(progress: fraction)
                            // .completeColor(.blue)
                    }
                }
                .frame(width: progressViewSize, height: progressViewSize)
                .padding(.top, 6)
                
                VStack(spacing: 9) {
                    Text(state.title)
                        .bold()
                    
                    if !state.message.isEmpty {
                        Text(state.message)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if let cancelAction = state.cancelAction {
                Button {
                    cancelAction.handler()
                    
                } label: {
                    Text(cancelAction.title)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background {
                            Capsule()
                                .fill(Color(UIColor.secondarySystemBackground))
                        }
                        .contentShape(Rectangle())
                }
                
                // Old UI
//                Divider()
//                
//                Button {
//                    cancelAction.handler()
//                    
//                } label: {
//                    Text(cancelAction.title)
//                        .padding(.horizontal)
//                        .padding(.vertical, 12)
//                        .contentShape(Rectangle())
//                }
                
            }
        }
        .padding()
        // It is difficult to get the size right without a maxWidth here -- without it the
        // available width (window width) is not available immediately, leading to wrong height)
        .frame(minWidth: 300, maxWidth: horizontalSizeClass == .compact ? 320 : 480)
    }
}

#Preview {
    @Previewable @State var determinateState: ProgressHUDState?
    @Previewable @State var indeterminateState: ProgressHUDState?
    
    VStack(spacing: 24) {
        Button("Present Determinate") {
            determinateState = .init(
                title: "Loading...",
                progress: .determinate(fraction: 0),
                message: "Aute ullamco laboris do culpa labore ullamco ipsum exercitation exercitation consectetur officia eu anim magna dolor."
            )
            
            Task {
                let steps = 3
                let duration = 3.0

                for i in 0...steps {
                    withAnimation {
                        determinateState?.progress = .determinate(fraction: Double(i) / Double(steps))
                    }

                    try await Task.sleep(for: .seconds(duration / Double(steps)))
                }
                
                try await Task.sleep(for: .seconds(0.5))
                
                determinateState = nil
            }
        }
        .progressHUD($determinateState)
        
        Button("Present Indeterminate") {
            indeterminateState = .init(
                title: "Loading...",
                progress: .indeterminate,
                message: "Lorem incididunt duis adipisicing commodo. Lorem incididunt duis adipisicing commodo.",
                cancelAction: .init(title: "Cancel") {
                    indeterminateState = nil
                }
            )
        }
        .progressHUD($indeterminateState)
        .onAppear {            
            indeterminateState = .init(
                title: "Submitting Test...",
                progress: .indeterminate,
                message: "",
                cancelAction: nil
            )
        }
    }
}
