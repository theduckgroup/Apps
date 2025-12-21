import SwiftUI
import AppShared
import Backend

extension View {
    @ViewBuilder
    func prepareForPreview() -> some View {
        self.tint(.theme)
            .environment(API.local)
            .environment(AppDefaults.mock)
    }
}
