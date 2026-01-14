import Foundation
import SwiftUI
import Common
import CommonUI

struct StockAdjustmentView: View {
    var adjustmentMeta: StockAdjustmentMeta
    var store: Store
    @State var adjustmentFetcher = ValueFetcher<StockAdjustment>()
    @State var containerSize: CGSize?
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView {
            contentView()
                .padding()
        }
        .onFirstAppear {
            fetchAdjustment()
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView()
                .padding(.bottom, 18)
            
            if let adjustment = adjustmentFetcher.value {
                tableView(adjustment)
                
            } else if let error = adjustmentFetcher.error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 18)
                
            } else if adjustmentFetcher.isFetching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 18)
            }
        }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 0) {
            GridRow(alignment: .firstTextBaseline) {
                Text("Store")
                    .bold()
                
                Text(store.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            
            Divider()
            
            GridRow(alignment: .firstTextBaseline) {
                Text("Date")
                    .bold()
                
                Text(adjustmentMeta.timestamp.formatted(.dateTime.weekday(.wide).day().month().year().hour().minute()))
            }
            .padding(.vertical, 12)
            
            Divider()
        }
    }
    
    @ViewBuilder
    private func tableView(_ adjustment: StockAdjustment) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 0) {
            // Header
            
            GridRow(alignment: .firstTextBaseline) {
                Text("Item")
                    .bold()
                
                Text("Quantity")
                    .bold()
                    .gridColumnAlignment(.trailing)
            }
            .padding(.top, 18)
            .padding(.bottom, 9)
            
            Divider()
            
            // Rows
            
            ForEach(Array(adjustment.changes.enumerated()), id: \.offset) { index, qtyChange in
                GridRow(alignment: .firstTextBaseline) {
                    let item = store.catalog.items.first { $0.id == qtyChange.itemId }

                    if let item {
                        Text(item.name)

                        Group {
                            if let set = qtyChange.set {
                                Text("Set to \(set.newValue)")
                                    .foregroundStyle(.secondary)

                            } else if let offset = qtyChange.offset {
                                let sign = offset.delta >= 0 ? "+" : "-"
                                let deltaText = "\(sign) \(abs(offset.delta))"
                                Text(deltaText)
                                    .foregroundStyle(.secondary)

                            } else {
                                Text("Missing operation")
                                    .foregroundStyle(.red)
                            }
                        }
                        .gridColumnAlignment(.trailing)
                        
                    } else {
                        Text("Item not found")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 12)

                Divider()
            }
        }
    }
    
    private func fetchAdjustment() {
        adjustmentFetcher.fetch {
            try await api.stockAdjustment(storeId: adjustmentMeta.storeId, adjustmentId: adjustmentMeta.id)
        }
    }
}

#Preview {
    PreviewView()
        .previewEnvironment()
}

private struct PreviewView: View {
    @State var store: Store?
    @State var adjustmentMeta: StockAdjustmentMeta?
    @Environment(API.self) var api
    
    var body: some View {
        NavigationStack {
            if let store, let adjustmentMeta {
                StockAdjustmentView(
                    adjustmentMeta: adjustmentMeta,
                    store: store
                )
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(.secondary)
            }
        }
        .onAppear {
            Task {
                do {
                    store = try await api.store()
                    let response = try await api.stockAdjustmentsMeta(storeId: store!.id, userId: User.mock.idString)
                    adjustmentMeta = response.data[0]
                    
                } catch {
                    logger.error("Unable to get adjustment metas")
                }
            }
        }
    }
}
