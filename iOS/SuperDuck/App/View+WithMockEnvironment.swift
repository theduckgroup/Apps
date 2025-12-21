import SwiftUI
import AppShared
import Backend
import CommonUI

extension View {
    @ViewBuilder
    func withMockEnvironment() -> some View {
        self.tint(.theme)
            .environment(Auth.mock)
            .environment(API.mock)
            .environment(AppDefaults.mock)
    }
}
