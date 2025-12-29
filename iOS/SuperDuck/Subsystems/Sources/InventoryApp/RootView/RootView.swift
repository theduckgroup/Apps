import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct RootView: View {
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
        }
        .onSceneBecomeActive {
        }
        .onReceive(api.eventHub.connectEvents) {
        }
//        .onReceive(api.eventHub.templatesChangeEvents) {
//            fetchTemplate()
//        }
//        .onReceive(api.eventHub.userReportsChangeEvents(userID: auth.user!.idString)) {
//            fetchReports()
//        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 36) {
                
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            loadingView()
        }
        .nonProdEnvWarningOverlay()
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
//        if true {
//            HStack {
//                ProgressView()
//                    .progressViewStyle(.circular)
//                    .tint(.secondary)
//                
//                Text("Loading...")
//                    .foregroundStyle(.secondary)
//            }
//            .padding(.horizontal, 21)
//            .padding(.vertical, 12)
//            .background {
//                Capsule()
//                    .fill(.regularMaterial)
//            }
//            .padding(.bottom, 24)
//            
//        } else if let error = templateError ?? reportsError {
//            VStack(alignment: .leading) {
//                Text(formatError(error))
//                    .foregroundStyle(.red)
//                
//                Button("Retry") {
//                    fetchTemplate()
//                    fetchReports()
//                }
//                .buttonStyle(.bordered)
//                .frame(maxWidth: .infinity, alignment: .trailing)
//            }
//            .fixedSize(horizontal: false, vertical: false)
//            .padding()
//            .frame(width: horizontalSizeClass == .regular ? 570 : nil)
//            .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil)
//            .background {
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(.regularMaterial)
//            }
//            .padding()
//        }
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
