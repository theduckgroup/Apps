import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import Auth

struct UserReportsView: View {
    var user: User
    var onView: (WSReportMeta) -> Void
    @State private var reports: [WSReportMeta]?
    @State private var reportsError: Error?
    @State private var isFetchingReports = false
    @State private var lastFetchReportsDate: Date?
    @State private var fetchTask: Task<Void, Never>?
    
    var body: some View {
        bodyImpl()
            .onSceneBecomeActive {
                fetchReports()
            }
            .onReceive(EventHub.shared.connectEvents) {
                print("UserReportsView: connect event")
                fetchReports()
            }
            .onReceive(EventHub.shared.userReportsChangeEvents(userID: user.id.uuidString)) {
                fetchReports()
            }
    }
    
    @ViewBuilder
    private func bodyImpl() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 15) {
                Text("Past Spendings")
                    .font(.system(size: 27, weight: .regular))
                
                if reports == nil && isFetchingReports {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let reportsError, !reportsError.isURLError {
                // Not shown for URL loading error because it is already shown in "New Spending" section
                
                Text(reportsError.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 15)
            }
            
            if let reports {
                if reports.count > 0 {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(reports, id: \.id) { report in
                            Row(report: report, isFirst: report.id == reports.first?.id) {
                                onView(report)
                            }
                        }
                        
                        Text("Data limited to the past 6 months.")
                            .foregroundStyle(.secondary)
                            .padding(.top)
                    }
                    .padding(.top, 24)
                
                } else {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .padding(.top, 15)
                }
            }
            
            if debugging {
                Text("[D] Last Fetched: \(lastFetchReportsDate?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
            }
        }
    }
    
    private func fetchReports() {
        fetchTask?.cancel()
        
        fetchTask = Task {
            do {
                isFetchingReports = true
                reportsError = nil
                
                defer {
                    isFetchingReports = false
                }
                
                if debugging {
                    // try await Task.sleep(for: .seconds(1))
                    // throw GenericError("Not connected to Internet")
                }
                
                if isRunningForPreviews {
                    self.reports = [.mock1, .mock2, .mock3]
                    self.reportsError = GenericError("Cupidatat est sit fugiat consectetur tempor fugiat culpa.")
                    return
                }
                
                var fetchedReports = try await API.shared.userReports(userID: user.id.uuidString)
                fetchedReports.sort(on: \.date, ascending: false)
                
                if let reports, reports.count > 0 {
                    withAnimation {
                        self.reports = fetchedReports
                    }
                } else {
                    self.reports = fetchedReports
                }
                
                lastFetchReportsDate = Date()
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                reportsError = error
            }
        }
    }
}

private struct Row: View {
    var report: WSReportMeta
    var isFirst: Bool
    var onView: () -> Void
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "text.document")
                .foregroundStyle(.secondary)
            
            let formattedDate = report.date.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
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
    }
}

#Preview {
    ScrollView {
        UserReportsView(
            user: .mock,
            onView: { _ in }
        )
        .padding()
    }
}
