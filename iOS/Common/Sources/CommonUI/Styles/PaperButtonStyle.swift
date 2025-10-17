import Foundation
import SwiftUI

public struct PaperButtonStyle: ButtonStyle {
    var prominent: Bool
    var wide: Bool
    var maxHeight: CGFloat?
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    public init(prominent: Bool = false, wide: Bool = false, maxHeight: CGFloat? = nil) {
        self.prominent = prominent
        self.wide = wide
        self.maxHeight = maxHeight
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        Group {
            if prominent {
                configuration.label
                    .bold(isEnabled)
                    .foregroundStyle(.white.opacity(isEnabled && !configuration.isPressed ? 1 : 0.5))
                
            } else {
                if configuration.isPressed {
                    configuration.label
                        .foregroundStyle(.tint.opacity(0.5))
                    
                } else if isEnabled {
                    configuration.label
                        .foregroundStyle(.tint)
                    
                } else {
                    configuration.label
                        .foregroundStyle(Color.secondary)
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
                ZStack {
                    Capsule()
                        .fill(.background)
                        .paperShadow()
                    
                    if colorScheme == .dark {
                        Capsule()
                            .strokeBorder(Color(UIColor.systemGray6), lineWidth: 1)
                    }
                }
            }
        }
    }
}

public extension ButtonStyle where Self == PaperButtonStyle {
    static func paper(prominent: Bool = false, wide: Bool = false, maxHeight: CGFloat? = nil) -> Self {
        PaperButtonStyle(prominent: prominent, wide: wide, maxHeight: maxHeight)
    }
}
