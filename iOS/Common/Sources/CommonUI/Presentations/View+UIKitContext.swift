import Foundation
import SwiftUI
import UIKit

public extension View {
    /// Adds a view controller to the SwiftUI view hierarchy. The view controller is hidden and
    /// stored in the given UIKit context object.
    ///
    /// The UIKit context can be used for presenting or pushing view controllers. It can also be
    /// used to access the added view controller and its view. The UIKit view has the same frame
    /// as the SwiftUI view.
    ///
    /// Example:
    /// ```
    /// @State var uikitContext = UIKitContext()
    ///
    /// // In view builder
    /// someView
    ///     .uikitContext(uikitContext)
    ///
    /// // To use the view controller
    /// uikitContext.present(...)
    /// uikitContext.push(...)
    /// let vc = uikitContext.viewController
    /// ```
    func uikitContext(_ uikitContext: UIKitContext) -> some View {
        background {
            ContextViewControllerRepresentable(uikitContext: uikitContext)
        }
    }
}

/// An object that stores reference to a view controller added to SwiftUI view hierarchy via
/// the `View.uikitContext` modifier.
@MainActor
public class UIKitContext {
    // `pendingPresent` and `pendingPush` keep the present/push calls that happen before the view
    // controller is added to window. When the the view controller is added to window, they are
    // used to "replay" those calls.
    
    fileprivate var _viewController: UIViewController?
    private var isAddedToWindow = false
    private var onAddedToWindowHandlers: [() -> Void] = []
    private var pendingPresent: (UIViewController, animated: Bool)?
    private var pendingPush: (UIViewController, animated: Bool)?

    public init() {}
    
    fileprivate func onAddedToWindow() {
        isAddedToWindow = true
        
        onAddedToWindowHandlers.forEach { $0() }
        onAddedToWindowHandlers.removeAll()

        if let (controller, animated) = pendingPresent {
            present(controller, animated: animated)
            pendingPresent = nil
        }
        
        if let (controller, animated) = pendingPush {
            push(controller, animated: animated)
            pendingPush = nil
        }
    }
    
    /// Registers a handler that is called when the context is added to window. If the context is
    /// already added to window, the handler is called immediately.
    public func onAddedToWindow(_ handler: @escaping () -> Void) {
        if isAddedToWindow {
            handler()
            
        } else {
            onAddedToWindowHandlers.append(handler)
        }
    }
    
    /// The context's view controller.
    public var viewController: UIViewController? {
        assertViewController()
        assert(isAddedToWindow, "View controller is not yet added to window")
        return _viewController
    }
    
    /// Presents a view controller.
    public func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        assertViewController()
        
        guard isAddedToWindow else {
            pendingPresent = (controller, animated)
            return
        }
        
        _viewController?.present(controller, animated: animated, completion: completion)
    }
    
    /// Dismisses currently presented view controller.
    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        assertViewController()
        
        guard isAddedToWindow else {
            pendingPresent = nil
            return
        }
        
        _viewController?.dismiss(animated: animated, completion: completion)
    }
    
    /// Pushes a view controller onto the nearest navigation controller.
    ///
    /// - Precondition: A navigation controller must exists in the view controller hierarchy.
    public func push(_ controller: UIViewController, animated: Bool) {
        assertViewController()
        
        guard isAddedToWindow else {
            pendingPush = (controller, animated)
            return
        }
        
        assert(_viewController?.navigationController != nil, "Navigation controller not found")
        _viewController?.navigationController?.pushViewController(controller, animated: animated)
    }
    
    /// Pushes a SwiftUI view onto the nearest navigation controller. The view is wrapped inside
    /// a `UIHostingController`.
    ///
    /// - Precondition: A navigation controller must exists in the view controller hierarchy.
    public func push(_ view: some View, animated: Bool) {
        push(UIHostingController(rootView: view), animated: true)
    }
    
    private func assertViewController() {
        assert(_viewController != nil, "View controller is nil. Did you forget to use `uikitContext` modifier?")
    }
}

private struct ContextViewControllerRepresentable: UIViewControllerRepresentable {
    var uikitContext: UIKitContext
    var onAddedToWindow: (() -> Void)?
    
    func makeUIViewController(context: Context) -> ViewController {
        let viewController = ViewController()
        viewController.view.isUserInteractionEnabled = false
        viewController.view.alpha = 0
        uikitContext._viewController = viewController
        
        viewController.onDidMoveToParent = { [weak uikitContext] in
            // Called when the view controller is added to window
            uikitContext?.onAddedToWindow()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // During SwiftUI view update, if the view controller needs to be replaced this method will
        // be called. However, it is first called for the *new* view controller, followed by the
        // *old* view controller. So it is wrong to set `uikitContext.viewController` here.
        //
        // (This is not relevant to us because it is more correct to set `uikitContext.viewController`
        // in `makeUIViewController`, but is an interesting details)
    }
}

private class ViewController: UIViewController {
    var onDidMoveToParent: (() -> Void)?
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        onDidMoveToParent?()
    }
}

#Preview {
    @Previewable @State var uikitContext = UIKitContext()
    @Previewable @State var didAppear = false
    
    NavigationStack {
        VStack(spacing: 24) {
            Button("Present") {
                uikitContext.present(UIHostingController(rootView: Text("Presented")), animated: true)
            }
            
            Button("Push") {
                uikitContext.push(Text("Pushed").navigationTitle("View2"), animated: true)
            }
        }
        .uikitContext(uikitContext)
        .navigationTitle("View")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !didAppear {
                // Uncomment to test present/push in onAppear
                // uikitContext.present(UIHostingController(rootView: Text("Presented")), animated: true)
                // uikitContext.push(UIHostingController(rootView: Text("Pushed").navigationTitle("View2")), animated: false)
                didAppear = true
            }
        }
    }
}
