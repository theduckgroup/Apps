import Foundation
public import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

public struct WeeklySpendingAppView: View {
    @State var templateFetcher = ValueFetcher<WSTemplate>()
    @State var reportsFetcher = ValueFetcher<[WSReportMeta]>()
    @State var presentedReportMeta: WSReportMeta?
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
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
                NewReportButton(template: templateFetcher.value)
                
                PastReportListView(reports: reportsFetcher.value) { reportMeta in
                    self.presentedReportMeta = reportMeta
                }
            }
            .padding()
        }
        .fetchOverlay(
            isFetching: templateFetcher.isFetching || reportsFetcher.isFetching,
            fetchError: templateFetcher.error ?? reportsFetcher.error,
            retry: {
                fetchTemplate()
                fetchReports()
            }
        )
        .nonProdEnvWarningOverlay()
    }
    
    private func fetchTemplate() {
        templateFetcher.fetch {
            if isRunningForPreviews {
                try await Task.sleep(for: .seconds(1))
                return try await api.mockTemplate()
            }
            
            return try await api.template()
        }
    }
    
    private func fetchReports() {
        reportsFetcher.fetch {
            if isRunningForPreviews {
                try await Task.sleep(for: .seconds(1))
                return [.mock1, .mock2, .mock3]
                // throw GenericError("Cupidatat est sit fugiat consectetur tempor fugiat culpa.")
            }
                
            return try await api.userReports(userID: auth.user!.idString)
        }
    }
}

#Preview {
    WeeklySpendingAppView()
        .previewEnvironment()
}
