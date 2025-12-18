import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import Auth

struct UserReportsView: View {
    var user: User
    var onView: (WSReportMeta) -> Void
    @State private var reportsResult: Result<[WSReportMeta], Error>?
    @State private var isFetchingReports = false
    @State private var lastFetchedReports: Date?
    
    var body: some View {
        bodyImpl()
//            .onFirstAppear {
//                fetchReports()
//            }
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
                
                if reportsResult?.value == nil && isFetchingReports {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            switch reportsResult {
            case .success(let reports):
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
                
            case .failure(let error):
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 15)
                
            case nil:
                EmptyView()
            }
            
            if debugging {
                Text("[D] Last Fetched: \(lastFetchedReports?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
            }
        }
    }
    
    private func fetchReports() {
        Task {
            do {
                isFetchingReports = true
                
                defer {
                    isFetchingReports = false
                }
                
                if debugging {
                    // try await Task.sleep(for: .seconds(1))
                    // throw GenericError("Not connected to Internet")
                }
                
                if isRunningForPreviews {
                    self.reportsResult = .success([.mock1, .mock2, .mock3])
                    return
                }

                if let reportsResult, reportsResult.isFailure {
                    self.reportsResult = nil // Clear failure
                }
                
                var reports = try await API.shared.userReports(userID: user.id.uuidString)
                reports.sort(on: \.date, ascending: false)
                
                if let reportsResult, reportsResult.isSuccess {
                    withAnimation {
                        self.reportsResult = .success(reports)
                    }
                } else {
                    self.reportsResult = .success(reports)
                }
                
                lastFetchedReports = Date()
                
            } catch {
                self.reportsResult = .failure(error)
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
