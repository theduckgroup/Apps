import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct RootView: View {
    @State var template: WSTemplate?
    @State var templateError: Error?
    @State var templateFetchDate: Date?
    @State var isFetchingTemplate = false
    @State var fetchTemplateTask: Task<Void, Never>?
    
    @State var reports: [WSReportMeta]?
    @State var reportsError: Error?
    @State var reportsFetchDate: Date?
    @State var isFetchingReports = false
    @State var fetchReportsTask: Task<Void, Never>?
    
    @State var presentedReportMeta: WSReportMeta?
    
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    public init() {}

    public var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Weekly Spending")
                .navigationDestination(item: $presentedReportMeta) { reportMeta in
                    PastReportView(reportMeta: reportMeta)
                }
        }
        .onFirstAppear {
            fetchTemplate()
            fetchReports()
        }
        .onSceneBecomeActive {
            fetchTemplate()
            fetchReports()
        }
        .onReceive(api.eventHub.connectEvents) {
            fetchTemplate()
            fetchReports()
        }
        .onReceive(api.eventHub.templatesChangeEvents) {
            fetchTemplate()
        }
        .onReceive(api.eventHub.userReportsChangeEvents(userID: auth.user!.idString)) {
            fetchReports()
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 36) {
                NewReportButton(template: template)
                
                PastReportListView(reports: reports) { reportMeta in
                    self.presentedReportMeta = reportMeta
                }
            }
            .padding()
        }
        .fetchOverlay(
            isFetching: isFetchingTemplate || isFetchingReports,
            fetchError: templateError ?? reportsError,
            retry: {
                fetchTemplate()
                fetchReports()
            }
        )
        .nonProdEnvWarningOverlay()
    }
    
//    @ViewBuilder
//    private func loadingView() -> some View {
//        if isFetchingTemplate || isFetchingReports {
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
//    }
    
    private func fetchTemplate() {
        fetchTemplateTask?.cancel()
        
        fetchTemplateTask = Task {
            do {
                isFetchingTemplate = true
                templateError = nil
                
                if debugging {
                    // try await Task.sleep(for: .seconds(0.5))
                }
                    
                let template = try await {
                    if isRunningForPreviews {
                        return try await api.mockTemplate()
                    }
                    
                    return try await api.template()
                }()
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                self.template = template
                self.templateError = nil
                self.templateFetchDate = Date()
                self.isFetchingTemplate = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                self.templateError = error
                self.isFetchingTemplate = false
            }
        }
    }
    
    private func fetchReports() {
        fetchReportsTask?.cancel()
        
        fetchReportsTask = Task {
            do {
                isFetchingReports = true
                reportsError = nil
                
                if debugging {
                    // try await Task.sleep(for: .seconds(0.5))
                }
                
                
                var fetchedReports: [WSReportMeta] = try await {
                    if isRunningForPreviews {
                        return [.mock1, .mock2, .mock3]
                        // throw GenericError("Cupidatat est sit fugiat consectetur tempor fugiat culpa.")
                    }
                        
                    return try await api.userReports(userID: auth.user!.idString)
                }()
                
                fetchedReports.sort(on: \.date, ascending: false)
                
                if let reports, reports.count > 0 {
                    withAnimation {
                        self.reports = fetchedReports
                    }
                } else {
                    self.reports = fetchedReports
                }
                
                self.reportsError = nil
                self.reportsFetchDate = Date()
                self.isFetchingReports = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                                
                self.reportsError = error
                self.isFetchingReports = false
            }
        }
    }
}

#Preview {
    RootView()
        .previewEnvironment()
}
