import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct StockChangeView: View {
    var changeMeta: StockChangeMeta
    var store: Store
    @State var change: StockChange?
    @State var error: Error?
    @State var isFetching = false
    @State var containerSize: CGSize?
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView(.vertical) {
            let containerSize = containerSize ?? .zero
            
            let needsReadablePadding = (
                horizontalSizeClass == .regular && verticalSizeClass == .regular &&
                containerSize.width > containerSize.height * 1.25
            )
            
            contentView()
                .padding()
                .frame(maxWidth: needsReadablePadding ? containerSize.width * 0.66 : nil, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .readSize(assignTo: $containerSize)
        .navigationTitle("Stock Change")
        .onFirstAppear {
            fetchChange()
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView()
                .padding(.bottom, 18)
            
            if let change {
                tableView(change)
                
            } else if let error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 18)
                
            } else if isFetching {
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
            
            GridRow(alignment: .firstTextBaseline) {
                Text("User")
                    .bold()
                
                if let change {
                    Text(change.user.email)
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            
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
                
                Text("Delta")
                    .bold()
                    .gridColumnAlignment(.trailing)
            }
            .padding(.top, 18)
            .padding(.bottom, 9)
            
            Divider()
            
            // Rows
            ForEach(change.itemQuantityChanges) { itemChange in
                GridRow(alignment: .firstTextBaseline) {
                    let item = store.catalog.items.first { $0.id == itemChange.itemId }
                    
                    if let item {
                        Text(item.name)
                        
                        let deltaText = itemChange.delta >= 0 ? "+\(itemChange.delta)" : "\(itemChange.delta)"
                        Text(deltaText)
                            .gridColumnAlignment(.trailing)
                            .foregroundStyle(itemChange.delta >= 0 ? .green : .red)
                        
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
        Task {
            do {
                isFetching = true
                
                defer {
                    isFetching = false
                }
                
                let change = try await api.stockChange(storeId: changeMeta.storeId, changeId: changeMeta.id)
                
                self.change = change
                
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        StockChangeView(
            changeMeta: .mock1,
            store: .mock
        )
    }
    .previewEnvironment()
}
