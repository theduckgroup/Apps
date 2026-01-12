import SwiftUI
import CommonUI

extension View {
    @ViewBuilder
    func previewEnvironment() -> some View {
        self.tint(.theme)
            .environment(Auth.mock)
            .environment(API.localWithMockAuth)
            .environment(AppDefaults())
            .environment(QuizAppDefaults())
            .environment(InventoryAppDefaults())
    }
}
