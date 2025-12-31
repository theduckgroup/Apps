import SwiftUI
import AppModule
import Backend
import CommonUI

extension View {
    @ViewBuilder
    func previewEnvironment() -> some View {
        self.tint(.theme)
            .environment(Auth.mock)
            .environment(API.mock)
            .environment(Defaults())
    }
}
