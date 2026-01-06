import Foundation
import SwiftUI

public struct ScrollViewWithReadableMargins<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State var containerSize: CGSize?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            let containerSize = containerSize ?? .zero
            
            let needsReadablePadding = (
                horizontalSizeClass == .regular && verticalSizeClass == .regular &&
                containerSize.width > containerSize.height * 1.25
            )
            
            content()
                .frame(maxWidth: needsReadablePadding ? containerSize.width * 0.75 : nil, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readSize(assignTo: $containerSize)
    }
}

