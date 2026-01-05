import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import Auth

struct RecentStockChangeListView: View {
    var changes: [StockChangeMeta]?
    var onView: (StockChangeMeta) -> Void
    @Environment(API.self) var api
    @Environment(Auth.self) var auth
    
    var body: some View {
        bodyImpl()
            .onSceneBecomeActive {
                fetchChanges()
            }
            .onReceive(api.eventHub.connectEvents) {
                print("PastStockChangeListView: connect event")
                fetchChanges()
            }
    }
    
    @ViewBuilder
    private func bodyImpl() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.system(size: 27, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let changes {
                if changes.count > 0 {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(changes) { change in
                            Row(change: change, isFirst: change.id == changes.first?.id) {
                                onView(change)
                            }
                        }
                    }
                    .padding(.top, 24)
                
                } else {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .padding(.top, 15)
                }
            }
        }
    }
    
    private func fetchChanges() {
        
    }
}

private struct Row: View {
    var change: StockChangeMeta
    var isFirst: Bool
    var onView: () -> Void
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.secondary)
            
            let formattedDate = change.timestamp.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
            Text(formattedDate)
            
            Spacer()
            
            Button {
                onView()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("View")
                    Image(systemName: "chevron.right").imageScale(.small)
                }
                .contentShape(Rectangle())
            }
        }
        .padding(.top, isFirst ? 0 : nil)
        .padding(.bottom)
        .overlay(alignment: .bottom) { Divider() }
        .onTapGesture {
            onView()
        }
    }
}

#Preview {
    @Previewable @State var changes: [StockChangeMeta]?
    
    ScrollView {
        if let changes {
            RecentStockChangeListView(
                changes: changes,
                onView: { _ in }
            )
            .padding()
            
        } else {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
    .onAppear {
        Task {
            do {
                changes = try await API.localWithMockAuth.stockChangesMeta(storeId: Store.defaultStoreID, userId: User.mock.idString)
                
            } catch {
                logger.error("Unable to get mock data: \(error)")
            }
        }
    }
    .previewEnvironment()
}
