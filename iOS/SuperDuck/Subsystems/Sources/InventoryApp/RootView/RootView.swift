import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI
import AsyncAlgorithms

public struct RootView: View {
    @State var storeFetcher = Fetcher<Vendor>()
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    public init() {}

    public var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Inventory")
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
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 36) {
                Button("Scan") {
                    
                }
            }
            .padding()
        }
        .fetchOverlay(
            isFetching: storeFetcher.isFetching,
            fetchError: storeFetcher.error,
            retry: { fetchStore(delay: true) }
        )
        .nonProdEnvWarningOverlay()
    }
    
    private func fetchStore(delay: Bool = false) {
        storeFetcher.fetch(delay: delay) {
            try await api.store()
        }
    }
    
//    private func fetchTemplate() {
//        fetchTemplateTask?.cancel()
//        
//        fetchTemplateTask = Task {
//            do {
//                isFetchingTemplate = true
//                templateError = nil
//                
//                if debugging {
//                    // try await Task.sleep(for: .seconds(0.5))
//                }
//                    
//                let template = try await {
//                    if isRunningForPreviews {
//                        return try await api.mockTemplate()
//                    }
//                    
//                    return try await api.template()
//                }()
//                
//                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
//                // throw GenericError("Not connected to internet")
//                
//                self.template = template
//                self.templateError = nil
//                self.templateFetchDate = Date()
//                self.isFetchingTemplate = false
//                
//            } catch {
//                guard !error.isCancellationError else {
//                    return
//                }
//                
//                self.templateError = error
//                self.isFetchingTemplate = false
//            }
//        }
//    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
