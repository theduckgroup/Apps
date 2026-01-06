import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct InventoryAppView: View {
    @State var storeFetcher = ValueFetcher<Store>()
    @State var adjustmentsFetcher = ValueFetcher<[StockAdjustmentMeta]>()
    @State var presentingStockView = false
    @State var selectedAdjustmentMeta: StockAdjustmentMeta?
    @State var ps = PresentationState()
    @State var presentingScanView = false
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    public init() {}

    public var body: some View {
        NavigationStack {
            bodyContent()
                .fetchOverlay(
                    isFetching: storeFetcher.isFetching || adjustmentsFetcher.isFetching,
                    fetchError: storeFetcher.error ?? adjustmentsFetcher.error,
                    retry: { fetchStore(delay: true) }
                )
                .nonProdEnvWarningOverlay()
                .navigationTitle("Inventory")
                .toolbar { toolbarContent() }
                .navigationDestination(isPresented: $presentingStockView) {
                    StockView()
                }
                .navigationDestination(item: $selectedAdjustmentMeta) { adjustmentMeta in
                    if let store = storeFetcher.value {
                        StockAdjustmentView(adjustmentMeta: adjustmentMeta, store: store)
                    }
                }
//                .fullScreenCover(isPresented: $presentingScanView) {
//                    ScanView(store: storeFetcher.value!, scanMode: .add)
//                }
                .presentations(ps)
        }
        .onAppear {
            fetchStore()
            fetchAdjustments()
        }
        .onSceneBecomeActive {
            fetchStore()
            fetchAdjustments()
        }
        .onReceive(api.eventHub.connectEvents) {
            fetchStore()
            fetchAdjustments()
        }
        .onReceive(api.eventHub.storeChangeEvents) {
            fetchStore()
            fetchAdjustments()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("View Stock") {
                presentingStockView = true
            }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 36) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Button("Add Items", systemImage: "plus.circle") {
                            // presentingScanView = true
                            ps.presentFullScreenCover {
                                ScanView(store: storeFetcher.value!, scanMode: .add)
                            }
                        }
                        
                        Button("Remove Items", systemImage: "minus.circle") {
                            ps.presentFullScreenCover {
                                ScanView(store: storeFetcher.value!, scanMode: .remove)
                            }
                        }
                    }
                    .buttonStyle(.primaryAction)
                    .disabled(storeFetcher.value == nil)
                }
                
                RecentStockAdjustmentListView(
                    adjustments: adjustmentsFetcher.value,
                    onView: { adjustmentMeta in
                        selectedAdjustmentMeta = adjustmentMeta
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
    
    private func fetchStore(delay: Bool = false) {
        storeFetcher.fetch(delay: delay) {
            try await api.store()
        }
    }
    
    private func fetchAdjustments(delay: Bool = false) {
        adjustmentsFetcher.fetch(delay: delay) {
            guard let userId = auth.user?.idString else {
                throw GenericError("User not logged in")
            }
            
            return try await api.stockAdjustmentsMeta(storeId: Store.defaultStoreID, userId: userId)
        }
    }
}

#Preview {
    TabView() {
        Tab("Inventory", image: "document.fill") {
            InventoryAppView()
        }
        
        Tab("FOH Test", image: "document.fill") {
            EmptyView()
        }
    }
    .previewEnvironment()
}
