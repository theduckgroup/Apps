import Foundation
import SwiftUI

struct FloatingTabItem<ID: Hashable> {
    let id: ID
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> AnyView
    
    init(id: ID, title: String, systemImage: String, @ViewBuilder content: @escaping () -> AnyView) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }
}
