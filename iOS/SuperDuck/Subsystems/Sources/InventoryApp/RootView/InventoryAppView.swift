import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct InventoryAppView: View {
    @State var storeFetcher = ValueFetcher<Store>()
    @State var presentingStockView = false
    @State var ps = PresentationState()
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    public init() {}

    public var body: some View {
        NavigationStack {
            bodyContent()
                .fetchOverlay(
                    isFetching: storeFetcher.isFetching,
                    fetchError: storeFetcher.error,
                    retry: { fetchStore(delay: true) }
                )
                .nonProdEnvWarningOverlay()
                .navigationTitle("Inventory")
                .toolbar { toolbarContent() }
                .navigationDestination(isPresented: $presentingStockView) {
                    StockView()
                }
        }
        .presentations(ps)
        .onFirstAppear {
            fetchStore()
        }
        .onSceneBecomeActive {
            fetchStore()
        }
        .onReceive(api.eventHub.connectEvents) {
            fetchStore()
        }
        .onReceive(api.eventHub.storeChangeEvents) {
            fetchStore()
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
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Button("Add Items", systemImage: "plus.circle") {
                            ps.presentFullScreenCover {
                                ScanView(store: storeFetcher.value!, mode: .add)
                            }
                        }
                        
                        Button("Remove Items", systemImage: "minus.circle") {
                            ps.presentFullScreenCover {
                                ScanView(store: storeFetcher.value!, mode: .remove)
                            }
                        }
                    }
                    .buttonStyle(.primaryAction)
                    .disabled(storeFetcher.value == nil)
                }
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
