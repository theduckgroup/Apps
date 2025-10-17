import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func paperShadow() -> some View {
        shadow(color: .black.opacity(0.075), radius: 15)
    }
}

extension View {
    @ViewBuilder
    func paperCapsuleBackground() -> some View {
        background {
            Capsule()
                .fill(.background)
                .paperShadow()
        }
    }
}
