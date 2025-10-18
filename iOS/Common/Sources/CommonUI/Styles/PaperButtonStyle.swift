import Foundation
import SwiftUI

// Default

public struct PaperButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        Group {
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
        .padding(.horizontal, horizontalPading)
        .padding(.vertical, verticalPadding)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
        .background {
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

public extension ButtonStyle where Self == PaperButtonStyle {
    static var paper: Self {
        PaperButtonStyle()
    }
}

// Prominent

public struct ProminentPaperButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        Group {
            configuration.label
                .bold(isEnabled)
                .foregroundStyle(.white.opacity(isEnabled && !configuration.isPressed ? 1 : 0.5))
        }
        .padding(.horizontal, horizontalPading)
        .padding(.vertical, verticalPadding)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
        .background {
            if isEnabled {
                Capsule().fill(.tint.opacity(configuration.isPressed ? 0.5 : 1))
                
            } else {
                ZStack {
                    Capsule().fill(.background)
                    Capsule().fill(Color(UIColor.systemFill))
                }
            }
        }
    }
}

public extension ButtonStyle where Self == ProminentPaperButtonStyle {
    static var paperProminent: Self {
        ProminentPaperButtonStyle()
    }
}

// Constants

private let minHeight: CGFloat = 40
private let horizontalPading: CGFloat = 12
private let verticalPadding: CGFloat = 12

// Preview

#Preview("Light") {
    PreviewButtons()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PreviewButtons()
        .preferredColorScheme(.dark)
}

private struct PreviewButtons: View {
    var body: some View {
        VStack(spacing: 24) {
            Button {} label: {
                Image(systemName: "person.fill")
            }
            .buttonStyle(.paper)
            
            Button {} label: {
                Image(systemName: "person.fill")
            }
            .buttonStyle(.paperProminent)
            
            Button {} label: {
                Text("Submit Result")
                    .padding(.horizontal, 9)
            }
            .buttonStyle(.paper)
            
            Button {} label: {
                Text("Submit Result")
                    .padding(.horizontal, 9)
            }
            .buttonStyle(.paperProminent)
        }
    }
}
