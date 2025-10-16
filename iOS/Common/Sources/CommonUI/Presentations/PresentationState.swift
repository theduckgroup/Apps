import Foundation
import Combine
import SwiftUI
import Common

public extension View {
    /// Adds presentations controlled by a presentation state.
    ///
    /// See ``PresentationState`` for more info.
    @ViewBuilder
    func presentations(_ state: PresentationState) -> some View {
        modifier(PresentationsModifier(state: state))
    }
}

/// Presentation state.
///
/// Use this to dynamically present views without having to add and manage states in the host view.
///
/// Usage:
/// ```swift
/// @State var state = PresentationState()
///
/// hostView
///     .presentations(state)
///
/// state.presentSheet {
///    Text("Hello")
/// }
///
/// state.presentFullScreenCover {
///    Text("Hello")
/// }
///
/// state.presentAlert(title: "Title", message: "Message", actions: {
///    Button("OK") {}
/// })
///
/// state.dismiss()
/// ```
///
/// If you need presentations other than the above, use `present(content:)` or `present(item:content:)` overloads.
@MainActor @Observable
public class PresentationState {
    /// List of presentations.
    ///
    /// This keeps track of:
    /// - The states of presentations (either `isPresented` or `item`)
    /// - The content of the presented view (as a view builder closure)
    ///
    /// Whenever a view is presented, an element is appended to this. The `presentations` modifier
    /// later looks at this to builds SwiftUI presentations.
    ///
    /// Note that this works because the Observation framework is capable of tracking changes to
    /// observable items in an array.
    fileprivate var presentations: [Presentation] = []
    
    /// Last present/dismiss task. This is used to make sure that present/dismiss called are serialized.
    ///
    /// Note: Don't set this to `nil` at the end of the task. It is easy to break the sequence that way.
    @ObservationIgnored private var lastTask: Task<Void, Never>?
    
    /// To assert that the state was added to a view before presentations.
    @ObservationIgnored fileprivate var isAddedToView = false
    
    fileprivate let uikitContext = UIKitContext()
    
    public init() {}
    
    /// Presents a view with `isPresented` binding.
    ///
    /// Example:
    /// ```swift
    /// presentationState.present { hostView, $isPresented in
    ///     // $isPresented is Binding<Bool>
    ///     hostView.sheet(isPresented: $isPresented) {
    ///         Text("Hello")
    ///     }
    /// }
    /// ```
    ///
    /// It is an error to call this while a view is already presented. In debug builds, it is an
    /// assertion failure. In release builds, the currently presented view is dismissed.
    public func present(_ content: @escaping (AnyView, Binding<Bool>) -> some View) {
        presentImpl(
            IsPresentedPresentation(contentBuilder: content)
        )
    }

    /// Presents a view with item binding.
    ///
    /// Example:
    /// ```swift
    /// presentationState.present(item: item) { hostView, $item in
    ///     // $item is Binding<Item?>
    ///     hostView.fullScreenCover(item: $item) { item in
    ///         Text("Item: \(item)")
    ///     }
    /// }
    /// ```
    ///
    /// It is an error to call this while a view is already presented. In debug builds, it is an
    /// assertion failure. In release builds, the currently presented view is dismissed.
    public func present<Item>(item: Item, @ViewBuilder content: @escaping (AnyView, Binding<Item?>) -> some View) {
        presentImpl(
            ItemPresentation(presentedItem: item, contentBuilder: content)
        )
    }
    
    private func presentImpl<P: Presentation>(_ presentation: P) {
        guard isAddedToView else {
            assertionFailureAndLogError("Attempting to use a presentation state that is not added to a view. Use `presentations` modifier to add the presentation state to a view.")
            return
        }
                
        let lastTask = self.lastTask
        
        self.lastTask = Task {
            await lastTask?.value
            
            if let last = presentations.last, last.isPresented {
                assertionFailureAndLogError("Attempting to present while there is already a presentation")
                last.dismiss()
            }

            // Remove old presentations
            // The most recent presentation is not removed because it may still be needed for dismiss animation
            // This happens when `dismiss` is followed immediately by `present`
            
            if presentations.count > 1 {
                presentations.removeFirst(presentations.count - 1)
            }
            
            // Append the presentation (with isPresented == false)
            
            presentations.append(presentation)
            
            // Wait for the host view/presentation to appear.
            // This makes sure that the presentation modififer (sheet, fullScreenCover etc) is
            // picked up by SwiftUI before isPresented is set to true. Without waiting, SwiftUI
            // will think that the presentation is added with isPresented immediately set to true
            // and therefore won't animate the presentation.
            
            await withCheckedContinuation { cont in
                presentation.onAppearHandler = { [weak presentation] in
                    presentation?.onAppearHandler = nil
                    cont.resume(returning: ())
                }
            }
            
            // Wait for presentedViewController to be nil
            // Needed when there are overlapping present/dismiss
            
            await withCheckedContinuation { cont in
                uikitContext.onAddedToWindow {
                    let controller = self.uikitContext.viewController!
                        
                    if controller.presentedViewController != nil {
                        // Wait for presentedViewController to be nil
                        // presentedViewController is not KVO compliant
                        // We check it using a tight loop
                        
                        Task {
                            let t = Date()
                            
                            while controller.presentedViewController != nil {
                                // Task.yield also works but will use 100% CPU
                                try await Task.sleep(for: .milliseconds(1))
                                
                                // Guard against infinite loop
                                // Dismissal animation takes ~700 ms most of the time but sometimes can go up to 1 sec
                                if Date().timeIntervalSince(t) > 3 {
                                    self.assertionFailureAndLogError("Run out of time waiting for presentedViewController to be nil")
                                    break
                                }
                            }
                            
                            cont.resume(returning: ())
                        }
                        
                    } else {
                        cont.resume(returning: ())
                    }
                }
            }
            
            // Present (set isPresented to true)
            
            presentation.present()
        }
    }
    
    /// Dismisses currently presented view.
    ///
    /// It is an error to call this while there is no presentation. In release builds, nothing
    /// happens. In debug builds, it is an assertion failure.
    public func dismiss() {
        let lastTask = self.lastTask
        
        self.lastTask = Task {
            await lastTask?.value
        
            guard let last = presentations.last, last.isPresented else {
                assertionFailureAndLogError("Attempting to dismiss while there is no presentation")
                return
            }
            
            last.dismiss()
        }
    }
    
    private func assertionFailureAndLogError(_ message: String) {
        logger.error(message)
        
        if !isRunningForPreviews {
            assertionFailure(message)
        }
    }
}

private struct PresentationsModifier: ViewModifier {
    @State var state: PresentationState
    
    func body(content: Content) -> some View {
        // Create a view that looks like this:
        //
        // content
        //   .background {
        //     Color.clear
        //       .id(p0.id)
        //       .sheet(isPresented: $p0.isPresented...)
        //     Color.clear
        //       .id(p1.id)
        //       .fullScreenCover(item: $p1.item...)
        //     ...
        //   }
        //
        // where p0, p1... are presentations stored in `state`.
        //
        // The `id` modifiers ensure that SwiftUI don't get confused when presentations are replaced.
        // Presentations are added in background to isolate the use of AnyView.
        
        content
            .background {
                ForEach(state.presentations, id: \.id) { p in
                    p.buildContent(Color.clear.id(p.id))
                        .onAppear {
                            p.onAppearHandler?()
                        }
                }
            }
            .uikitContext(state.uikitContext)

        let _ = state.isAddedToView = true
    }
}

/// A presentation. Conforming types correspond to different ways SwiftUI does presentation.
///
/// A presentation is always created with `isPresented == false`.
private protocol Presentation: AnyObject {
    var id: UUID { get }
    
    /// Handler called when the presentation/host view appears.
    var onAppearHandler: (() -> Void)? { get set }
    
    /// Builds the presentation, i.e. adding the presentation modifier to host view.
    ///
    /// Example: `hostView` -> `hostView.sheet(isPresented: $p.isPresented)`
    func buildContent(_ hostView: some View) -> AnyView
    
    /// Whether the presentation is presented.
    var isPresented: Bool { get }
    
    /// Sets the presentation's state to presented.
    func present()
    
    /// Sets the presentations's state to dismissed/not presented.
    func dismiss()
}

/// Presentation whose state is a `isPresented` boolean.
///
/// This corresponds to modifiers like `sheet(isPresented:...)`, `fullScreenCover(isPresented:...)`.
@Observable
private class IsPresentedPresentation: Presentation, CustomDebugStringConvertible {
    let id = UUID()
    let contentBuilder: (AnyView, Binding<Bool>) -> any View
    var isPresented: Bool
    var onAppearHandler: (() -> Void)?
    
    init(contentBuilder: @escaping (AnyView, Binding<Bool>) -> some View) {
        self.isPresented = false
        self.contentBuilder = contentBuilder
    }
    
    func buildContent(_ hostView: some View) -> AnyView {
        @Bindable var p = self
        return AnyView(p.contentBuilder(AnyView(hostView), $p.isPresented))
    }
    
    func present() {
        isPresented = true
    }
    
    func dismiss() {
        isPresented = false
    }
    
    var debugDescription: String {
        "<\(Self.self) id=\(id) isPresented=\(isPresented)>"
    }
}

/// Presentation whose state is an optional item.
///
/// This corresponds to modifiers like `sheet(item:...)`, `fullScreenCover(item:...)`.
@Observable
private class ItemPresentation: Presentation, CustomDebugStringConvertible {
    let id = UUID()
    let contentBuilder: (AnyView, Binding<Any?>) -> any View
    let presentedItem: Any // The value `item` is set to when presented
    var item: Any?
    var onAppearHandler: (() -> Void)?
    
    init<Item>(presentedItem: Item, contentBuilder: @escaping (AnyView, Binding<Item?>) -> some View) {
        self.item = nil
        self.presentedItem = presentedItem
        
        // Erase `(AnyView, Binding<Item?>) -> some View` to `(AnyView, Binding<Any?>) -> any View`
        let erasedContentBuilder: (AnyView, Binding<Any?>) -> any View = { view, erasedBinding in
            // Recover `Binding<Item?>` from `Binding<Any?>`
            let itemBinding = Binding<Item?> {
                assert(erasedBinding.wrappedValue == nil || erasedBinding.wrappedValue is Item)
                return erasedBinding.wrappedValue as? Item
                
            } set: { newValue in
                erasedBinding.wrappedValue = newValue
            }
            
            return contentBuilder(view, itemBinding)
        }
        
        self.contentBuilder = erasedContentBuilder
    }
    
    func buildContent(_ hostView: some View) -> AnyView {
        @Bindable var p = self
        return AnyView(p.contentBuilder(AnyView(hostView), $p.item))
    }
    
    var isPresented: Bool {
        item != nil
    }
    
    func present() {
        item = presentedItem
    }
    
    func dismiss() {
        item = nil
    }
    
    var debugDescription: String {
        "<\(Self.self) id=\(id.uuidString) item=\(item.map(String.init(describing:)) ?? "nil")>"
    }
}
