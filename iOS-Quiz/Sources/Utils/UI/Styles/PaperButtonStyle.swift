import Foundation
import SwiftUI

struct PaperButtonStyle: ButtonStyle {
    var prominent = false
    var maxHeight: CGFloat?
    
    func makeBody(configuration: Configuration) -> some View {
        if prominent {
            withPadding {
                configuration.label
                    .bold()
                    .foregroundStyle(.white)
            }
            .background {
                Capsule().fill(.tint)
            }
            
        } else {
            withPadding {
                configuration.label
                    .foregroundStyle(.tint)
            }
            .background {
                Capsule()
                    .fill(.background)
                    .paperShadow()
            }
        }
    }
    
    private func withPadding(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .padding(.horizontal, 24)
            .padding(.vertical, 9)
            .frame(minHeight: 44, maxHeight: maxHeight)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PaperButtonStyle {
    static func paper(prominent: Bool = false, maxHeight: CGFloat? = nil) -> Self {
        PaperButtonStyle(prominent: prominent, maxHeight: maxHeight)
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
