import SwiftUI
import AppShared
import Backend

extension View {
    @ViewBuilder
    func withMockEnvironment() -> some View {
        self.tint(.theme)
            .environment(Auth.mock)
            .environment(API.mock)
            .environment(AppDefaults.mock)
    }
}
