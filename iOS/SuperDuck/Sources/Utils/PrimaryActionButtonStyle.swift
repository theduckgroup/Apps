import Foundation
import SwiftUI
import CommonUI

public struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        Group {
            if isEnabled {
                configuration.label
                    .foregroundStyle(Color.white)
                
            } else {
                configuration.label
                    .foregroundStyle(Color.white)
            }
        }
        .fontWeight(.semibold)
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .frame(minHeight: 42)
        .modified {
            if #available(iOS 26, *) {
                $0.glassEffect(.regular.tint(.accentColor).interactive())
            } else {
                $0.background {
                    RoundedRectangle(cornerRadius: 9).fill(.tint.opacity(configuration.isPressed ? 0.75 : 1))
                }
            }
        }
        .contentShape(Rectangle())
    }
}

public extension ButtonStyle where Self == PrimaryActionButtonStyle {
    /// Button style used for primary action buttons in app root views.
    static var primaryAction: Self {
        PrimaryActionButtonStyle()
    }
}

#Preview {
    ZStack(alignment: .center) {
        Button {
            
        } label: {
            Label("Hello", systemImage: "plus.circle")
        }
        .buttonStyle(.primaryAction)
    }
}
