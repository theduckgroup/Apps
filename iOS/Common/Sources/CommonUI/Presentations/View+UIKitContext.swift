import Foundation
import SwiftUI
import UIKit

public extension View {
    /// Adds a UIKit context to the SwiftUI view hierarchy.
    ///
    /// The UIKit context can be used for presenting or pushing UIKit view controllers.
    ///
    /// The UIKit context also has a view controller, which is not visible and has the same frame
    /// as the SwiftUI view it is added to. If you need to access this view controller, make sure
    /// you do it inside `onAddedToWindow`.
    ///
    /// Example:
    /// ```
    /// @State var uikitContext = UIKitContext()
    ///
    /// // Attach
    /// someView
    ///     .attach(uikitContext)
    ///
    /// // Use
    /// uikitContext.present(...)
    /// uikitContext.push(...)
    ///
    /// // Access UIKit view controller
    /// uikitContext.onAddedToWindow {
    ///   // uikitContext.viewController can be used
    /// }
    /// ```
    func attach(_ uikitContext: UIKitContext) -> some View {
        background {
            let _ = uikitContext.isAttached = true
            ContextViewControllerRepresentable(uikitContext: uikitContext)
        }
    }
}

/// An object that stores reference to a view controller added to SwiftUI view hierarchy via
/// the `View.uikitContext` modifier.
@MainActor
public class UIKitContext {
    fileprivate var _viewController: UIViewController?
    fileprivate var isAttached = false
    private var isAddedToWindow = false
    private var onAddedToWindowHandlers: [() -> Void] = []
    
    public init() {}
    
    fileprivate func onAddedToWindow() {
        isAddedToWindow = true
        onAddedToWindowHandlers.forEach { $0() }
        onAddedToWindowHandlers.removeAll()
    }
    
    /// Registers a handler that is called when the context is added to window. If the context is
    /// already added to window, the handler is called immediately.
    public func onAddedToWindow(_ handler: @escaping () -> Void) {
        assert(isAttached, "Attempting to use UIKitContext while it is not attached to a view")
        
        if isAddedToWindow {
            handler()
            
        } else {
            onAddedToWindowHandlers.append(handler)
        }
    }
    
    /// The context's view controller.
    public var viewController: UIViewController {
        assert(isAttached, "Attempting to use UIKitContext while it is not attached to a view")
        assert(isAddedToWindow, "View controller is not yet added to window. Make sure you access view controller inside `onAddedToWindow`.")
        return _viewController!
    }
    
    /// Presents a view controller.
    public func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        onAddedToWindow { [weak self] in
            self?.viewController.present(controller, animated: animated, completion: completion)
        }
    }
    
    /// Dismisses currently presented view controller.
    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        onAddedToWindow { [weak self] in
            self?.viewController.dismiss(animated: animated, completion: completion)
        }
    }
    
    /// Pushes a view controller onto the nearest navigation controller.
    ///
    /// - Precondition: A navigation controller must exists in the view controller hierarchy.
    public func push(_ controller: UIViewController, animated: Bool) {
        onAddedToWindow { [weak self] in
            guard let self else {
                return
            }
            
            assert(viewController.navigationController != nil, "Navigation controller not found")
            viewController.navigationController?.pushViewController(controller, animated: animated)
        }
    }
    
    /// Pushes a SwiftUI view onto the nearest navigation controller. The view is wrapped inside
    /// a `UIHostingController`.
    ///
    /// - Precondition: A navigation controller must exists in the view controller hierarchy.
    public func push(_ view: some View, animated: Bool) {
        push(UIHostingController(rootView: view), animated: true)
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
    
    NavigationStack {
        VStack(spacing: 24) {
            Button("Present") {
                uikitContext.present(UIHostingController(rootView: Text("Presented")), animated: true)
            }
            
            Button("Push") {
                uikitContext.push(Text("Pushed").navigationTitle("View2"), animated: true)
            }
        }
        .attach(uikitContext)
        .navigationTitle("View")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            // Uncomment to test present/push on appear
            // uikitContext.present(UIHostingController(rootView: Text("Presented")), animated: true)
            // uikitContext.push(UIHostingController(rootView: Text("Pushed").navigationTitle("View2")), animated: false)
        }
    }
}
