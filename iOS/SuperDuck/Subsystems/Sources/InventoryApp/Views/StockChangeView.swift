import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct StockChangeView: View {
    var changeMeta: StockChangeMeta
    var store: Store
    @State var changeFetcher = ValueFetcher<StockChange>()
    @State var containerSize: CGSize?
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView {
            contentView()
                .padding()
        }
        // .navigationTitle("Stock Change")
        .onFirstAppear {
            fetchChange()
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView()
                .padding(.bottom, 18)
            
            if let change = changeFetcher.value {
                tableView(change)
                
            } else if let error = changeFetcher.error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 18)
                
            } else if changeFetcher.isFetching {
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
                
                Text(changeMeta.timestamp.formatted(.dateTime.weekday(.wide).day().month().year().hour().minute()))
            }
            .padding(.vertical, 12)
            
            Divider()
            
//            GridRow(alignment: .firstTextBaseline) {
//                Text("User")
//                    .bold()
//                
//                if let change = changeFetcher.value {
//                    Text(change.user.email)
//                } else {
//                    Text("—")
//                        .foregroundStyle(.secondary)
//                }
//            }
//            .padding(.vertical, 12)
            
            Divider()
        }
    }
    
    @ViewBuilder
    private func tableView(_ change: StockChange) -> some View {
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
            
            ForEach(Array(change.changes.enumerated()), id: \.offset) { index, qtyChange in
                GridRow(alignment: .firstTextBaseline) {
                    let item = store.catalog.items.first { $0.id == qtyChange.itemId }
                    
                    if let item {
                        Text(item.name)
                        
                        let sign = qtyChange.delta >= 0 ? "+" : "-"
                        let deltaText = "\(sign) \(abs(qtyChange.delta))"
                        
                        Text(deltaText)
                            .gridColumnAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            // .foregroundStyle(itemChange.delta >= 0 ? .green : .red)
                        
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
    
    private func fetchChange() {
        changeFetcher.fetch {
            try await api.stockChange(storeId: changeMeta.storeId, changeId: changeMeta.id)
        }
    }
}

#Preview {
    PreviewView()
        .previewEnvironment()
}

struct PreviewView: View {
    @State var store: Store?
    @State var changeMeta: StockChangeMeta?
    @Environment(API.self) var api
    
    var body: some View {
        NavigationStack {
            if let store, let changeMeta {
                StockChangeView(
                    changeMeta: changeMeta,
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
                    let changeMetas = try await api.stockChangesMeta(storeId: store!.id, userId: User.mock.idString)
                    changeMeta = changeMetas[0]
                    
                } catch {
                    logger.error("Unable to get change metas")
                }
            }
        }
    }
}
