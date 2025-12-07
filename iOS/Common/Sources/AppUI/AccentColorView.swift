import Foundation
import SwiftUI

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
        HStack(spacing: 15) {
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
            
//            ColorPicker("", selection: $accentColor)
//                .fixedSize()
            
            Spacer()
        }
    }
    
    private enum Lightness {
        case light
        case dark
    }
}
