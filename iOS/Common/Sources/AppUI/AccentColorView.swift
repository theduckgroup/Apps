import Foundation
import SwiftUI
import Flow

struct AccentColorView: View {
    @Binding var accentColor: Color
    @State var containerSize: CGSize?
    
    private let colorWithLightness: [Color] = [
        Color.theme,
        Color.red,
        Color.orange,
        Color.yellow,
        // Color.pink, // Very similar to red
        Color.purple,
        Color.blue,
        Color.indigo,
        Color.teal,
        Color.mint,
        Color.green,
        Color.brown,
        Color.gray,
    ]
    
    var body: some View {
        // Equation:
        // swatchSize * countPerRow + minSpacing * (countPerRow - 1) <= width
        // countPerRow <= (width + spacing) / (swatchSize + spacing)
        // spacing = (width - swatchSize * countPerRow) / (countPerRow - 1)
        
        let width = containerSize?.width ?? 0
        
        let swatchSize: CGFloat = 32
        let minSpacing: CGFloat = 15
        let countPerRow = ((width + minSpacing) / (swatchSize + minSpacing)).rounded(.down)
        let spacing = (width - swatchSize * countPerRow) / (countPerRow - 1)
        
        // `distributeItemsEvenly: true`: breaks into two rows with even number of items
        // `justified: true`: applies also to the last row!
        HFlow(itemSpacing: spacing, rowSpacing: minSpacing) {
            ForEach(Array(colorWithLightness.enumerated()), id: \.offset) { index, color in
                Button {
                    accentColor = color
                    
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: swatchSize, height: swatchSize)
                        .overlay {
                            if color.isApproximatelyEqualTo(accentColor) {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .padding(2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // `maxWidth: .infinity` is needed for `readSize`
        .readSize(assignTo: $containerSize)
    }
}
