import Foundation
import SwiftUI

struct PaperButtonStyle: ButtonStyle {
    var prominent = false
    var wide = false
    var maxHeight: CGFloat?
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if prominent {
                configuration.label
                    .bold(isEnabled)
                    .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.5))
                
            } else {
                if configuration.isPressed {
                    configuration.label
                        .foregroundStyle(.tint.opacity(0.5))
                    
                } else {
                    configuration.label
                        .foregroundStyle(.tint)
                }
            }
        }
        .padding(.horizontal, wide ? 24 : 12)
        .padding(.vertical, 12)
        .frame(minWidth: 44, minHeight: 44, maxHeight: maxHeight)
        .contentShape(Rectangle())
        .background {
            if prominent {
                if isEnabled {
                    Capsule().fill(.tint.opacity(configuration.isPressed ? 0.5 : 1))
                    
                } else {
                    ZStack {
                        Capsule().fill(.background)
                        Capsule().fill(Color(UIColor.systemFill))
                    }
                }
            } else {
                Capsule()
                    .fill(.background)
                    .paperShadow()
            }
        }
    }
}

extension ButtonStyle where Self == PaperButtonStyle {
    static func paper(prominent: Bool = false, wide: Bool = false, maxHeight: CGFloat? = nil) -> Self {
        PaperButtonStyle(prominent: prominent, wide: wide, maxHeight: maxHeight)
    }
}

//struct MyGlassButtonStyle: ButtonStyle {
//    var prominent = false
//    
//    func makeBody(configuration: Configuration) -> some View {
//        Group {
//            if prominent {
//                configuration.label
//                    .bold()
//                    .foregroundStyle(.white)
//            } else {
//                configuration.label
//                    .foregroundStyle(.tint)
//            }
//        }
//        .padding(.horizontal, 24)
//        .padding(.vertical, 9)
//        .frame(minHeight: 44, maxHeight: .infinity)
//        .contentShape(Rectangle())
//        .background {
//            prominent ? Capsule().fill(.tint) : nil
//        }
//        .glassEffectShim()
//    }
//}
