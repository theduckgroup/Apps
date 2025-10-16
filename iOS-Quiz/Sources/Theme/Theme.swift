import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func applyTheme() -> some View {
        self.preferredColorScheme(.dark)
    }
}
