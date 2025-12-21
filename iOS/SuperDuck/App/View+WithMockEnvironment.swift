import SwiftUI
import AppShared
import Backend
import CommonUI

extension View {
    @ViewBuilder
    func withMockEnvironment() -> some View {
        self.tint(.theme)
            .environment(API.local)
            .environment(AppDefaults.mock)
    }
}
