import Foundation
import SwiftUI

public extension View {
    /// Reads the view's size.
    ///
    /// Example:
    /// ```
    /// @State var size: CGSize?
    ///
    /// content
    ///     .readSize(assignTo: $size)
    /// ```
    ///
    /// To read the available width, use `frame(maxWidth: .infinity)` before using this.
    ///
    /// - Note: This is implemented using `onGeometryChange`. Using `onGeometryChange` directly
    /// sometimes causes infinite update loop due to floating point error.
    @ViewBuilder
    func readSize(assignTo: Binding<CGSize?>) -> some View {
        onGeometryChange(for: CGSize.self, of: \.size) { newValue in
            if let oldValue = assignTo.wrappedValue {
                // Only assign if new value is not approximately equal to old value. Approximation
                // is needed because SwiftUI returns slightly off values. Always assigning will
                // cause infinite view updates.
                
                if !newValue.isApproximatelyEqualTo(oldValue) {
                    assignTo.wrappedValue = newValue
                }
                
            } else {
                assignTo.wrappedValue = newValue
            }
        }
    }
    
    /// Reads the view's safe area insets.
    ///
    /// Example:
    /// ```
    /// @State var safeAreaInsets: EdgeInsets?
    ///
    /// content
    ///     .readSafeAreaInsets(assignTo: $safeAreaInsets)
    /// ```
    ///
    /// - Note: This is implemented using `onGeometryChange`. Using `onGeometryChange` directly
    /// sometimes causes infinite update loop due to floating point error.
    @ViewBuilder
    func readSafeAreaInsets(assignTo: Binding<EdgeInsets?>) -> some View {
        onGeometryChange(for: EdgeInsets.self, of: \.safeAreaInsets) { newValue in
            if let oldValue = assignTo.wrappedValue {
                // Only assign if new value is not approximately equal to old value. Approximation
                // is needed because SwiftUI returns slightly off values. Always assigning will
                // sometimes cause infinite view updates.
                
                if !newValue.isApproximatelyEqualTo(oldValue) {
                    assignTo.wrappedValue = newValue
                }
                
            } else {
                assignTo.wrappedValue = newValue
            }
        }
    }
}

private extension CGSize {
    func isApproximatelyEqualTo(_ other: CGSize, epsilon: CGFloat = 1e-3) -> Bool {
        abs(width - other.width) < epsilon &&
        abs(height - other.height) < epsilon
    }
}

private extension EdgeInsets {
    func isApproximatelyEqualTo(_ other: EdgeInsets, epsilon: CGFloat = 1e-3) -> Bool {
        abs(top - other.top) < epsilon &&
        abs(leading - other.leading) < epsilon &&
        abs(bottom - other.bottom) < epsilon &&
        abs(trailing - other.trailing) < epsilon
    }
}

#Preview {
    @Previewable @State var size: CGSize?
    @Previewable @State var safeAreaInsets: EdgeInsets?
    
    // Use iPhone in landscape orientation to test safe area insets
    
    VStack {
        Text("Text")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.mint)
            .readSize(assignTo: $size)
            .readSafeAreaInsets(assignTo: $safeAreaInsets)
        
        Text("Size: \(size.map(String.init(describing:)) ?? "<nil>")")
        Text("Safe Area Insets: \(safeAreaInsets.map(String.init(describing:)) ?? "<nil>")")
    }
    .multilineTextAlignment(.center)
}
