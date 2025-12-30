import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI
import AsyncAlgorithms

public struct RootView: View {
    @State var storeFetcher = Fetcher<Vendor>()
    @State var showsStock = false
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(AppDefaults.self) var appDefaults
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
                .navigationDestination(isPresented: $showsStock) {
                    InventoryView()
                }
        }
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
                showsStock = true
            }
//            .buttons
//            .modified {
//                if #available(iOS 26, *) {
//                    $0.buttonStyle(.borderless)
//                } else {
//                    $0.buttonStyle(.bordered)
//                }
//            }
            
//            Menu {
//                Button("Add Items", systemImage: "plus.circle.fill") {
//                    
//                }
//                .buttonStyle(.borderedProminent)
//                
//                Button("Remove Items", systemImage: "minus.circle.fill") {
//                    
//                }
//                .buttonStyle(.borderedProminent)
//                
//            } label: {
//                HStack(alignment: .firstTextBaseline, spacing: 6) {
//                    Image(systemName: "qrcode.viewfinder")
//                        
//                    Text("Scan")
//                }
//                .padding(.horizontal, 6)
//                // Label("Scan", systemImage: "qrcode.viewfinder")
//            }
//            .modified {
//                if #available(iOS 26, *) {
//                    $0.buttonStyle(.glass)
//                } else {
//                    $0.buttonStyle(.borderedProminent)
//                }
//            }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Button("Add Items", systemImage: "plus.circle") {
                            
                        }
                        
                        Button("Remove Items", systemImage: "minus.circle") {
                            
                        }
                    }
                    .bold()
                    .disabled(true)
                    .buttonStyle(.primaryAction)
                }
                
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Stock")
//                        .font(.system(size: 27, weight: .regular))
//                    
//                    Button {
//                        
//                    } label: {
//                        HStack(alignment: .firstTextBaseline) {
//                            Text("View Stock")
//                            Image(systemName: "chevron.right")
//                        }
//                        .padding(.horizontal, 6)
//                    }
//                    .buttonStyle(.bordered)
//                }
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
            RootView()
        }
        
        Tab("FOH Test", image: "document.fill") {
            EmptyView()
        }
    }
    .previewEnvironment()
}
