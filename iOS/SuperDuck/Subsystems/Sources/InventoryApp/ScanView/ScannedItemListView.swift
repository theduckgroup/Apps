import Foundation
import SwiftUI

struct ScannedItemListView: View {
    var scannedItems: [ScanRecord]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(scannedItems.grouped(), id: \.storeItem.id) { group in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text(group.storeItem.name)
                            Text(group.storeItem.code)
                        }

                        Spacer()

                        Text("\(group.totalQuantity)")
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
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 5),
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 3),
                .init(storeItem: .init(id: "rock-salt", name: "Rock Salt", code: "RKST"), quantity: 2),
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 1),
                .init(storeItem: .init(id: "rock-salt", name: "Rock Salt", code: "RKST"), quantity: 4),
            ]
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Scanned Items")
    }
    .preferredColorScheme(.dark)
}
