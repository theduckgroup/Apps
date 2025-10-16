import SwiftUI

public extension View {
    /// Presents an alert. The alert is presented if `presenting` has non-nil value. When the alert
    /// is dismissed, `presenting`'s value is set to `nil`.
    func alert<T, A: View, M: View>(
        _ title: String,
        presenting: Binding<T?>,
        @ViewBuilder actions: (T) -> A = { (_: T) in EmptyView() },
        @ViewBuilder message: (T) -> M
    ) -> some View {
        return alert(title, isPresented: presenting.isNotNil(), presenting: presenting.wrappedValue, actions: actions, message: message)
    }
    
    /// Presents an alert. The alert is presented if `presenting` has non-nil value. When the alert
    /// is dismissed, `presenting`'s value is set to `nil`.
    func alert<A: View, M: View>(
        _ title: String,
        presenting: Binding<Error?>,
        @ViewBuilder actions: (Error) -> A = { _ in EmptyView() },
        @ViewBuilder message: (Error) -> M = { Text($0.localizedDescription) }
    ) -> some View {
        return alert(title, isPresented: presenting.isNotNil(), presenting: presenting.wrappedValue, actions: actions, message: message)
    }
}

private extension Binding  {
    func isNotNil<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        .init(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}
