import Foundation
import SwiftUI

public extension View {
    @ViewBuilder
    func glassEffectShim() -> some View {
        glassEffectShim(in: Capsule())
    }
    
    @ViewBuilder
    func glassEffectShim(in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            // background(.ultraThickMaterial, in: shape)
            background(.white, in: shape)
        }
    }
}
