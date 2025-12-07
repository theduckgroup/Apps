import Foundation
import SwiftUI
import Flow

struct AccentColorView: View {
    @Binding var accentColor: Color
    private let colorWithLightness: [(Color, Lightness)] = [
        (Color.theme, .dark),
        (Color.red, .dark),
        (Color.green, .light),
        (Color.indigo, .dark),
        (Color.teal, .dark),
        (Color.yellow, .light),
        (Color.purple, .dark),
        (Color.brown, .dark),
    ]
    
    var body: some View {
        // `distributeItemsEvenly: true`: breaks into two rows with even number of items
        HFlow(itemSpacing: 15, rowSpacing: 15, justified: true) {
            ForEach(Array(colorWithLightness.enumerated()), id: \.offset) { index, colorWithLightness in
                let (color, _) = colorWithLightness
                
                Button {
                    accentColor = color
                    
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            let equal = color.isApproximatelyEqualTo(accentColor)
                            
                            if equal {
                                Circle()
                                    .strokeBorder(
                                        // lightness == .light ? Color.black.opacity(0.9) : Color.white,
                                        Color.white,
                                        lineWidth: 2
                                    )
                                    .padding(2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 600) // Must not be .infinite for `justified: true` to work
    }
    
    private enum Lightness {
        case light
        case dark
    }
}
