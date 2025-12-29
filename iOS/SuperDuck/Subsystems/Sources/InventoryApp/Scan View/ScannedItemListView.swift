import Foundation
import SwiftUI

struct ScannedItemListView: View {
    // @State var store = InventoryStore.shared
    var scannedItems: [ScannedItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(scannedItems.grouped(), id: \.item.itemID) { group in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text(group.item.name)
                            Text(group.item.code)
                        }
                        
                        Spacer()
                        
                        Text("\(group.count)")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScannedItemListView(
            scannedItems: [
                .init(itemID: "water-bottle", code: "WTBLT", name: "Water Bottle"),
                .init(itemID: "water-bottle", code: "WTBLT", name: "Water Bottle"),
                .init(itemID: "rock-salt", code: "RKST", name: "Rock Salt"),
                .init(itemID: "water-bottle", code: "WTBLT", name: "Water Bottle"),
                .init(itemID: "rock-salt", code: "RKST", name: "Rock Salt"),
            ]
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Scanned Items")
    }
    .preferredColorScheme(.dark)
}
