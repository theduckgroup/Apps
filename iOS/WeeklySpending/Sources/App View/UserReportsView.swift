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
    
    var body: some View {
        bodyImpl()
            .onFirstAppear {
                fetchReports()
            }
            .onReceive {
                EventHub.shared.userReportsChanged(userID: user.id.uuidString)
            } perform: {
                fetchReports()
            }
    }
    
    @ViewBuilder
    private func bodyImpl() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 15) {
                Text("Past Spendings")
                    .font(.system(size: 27, weight: .regular))
                
                if isFetchingReports {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                    
                } else {
                    Button {
                        fetchReports(delay: true)
                        
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .imageScale(.large)
                            .rotationEffect(.degrees(30))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        
            switch reportsResult {
            case .success(let reports):
                if reports.count > 0 {
                    LazyVStack(spacing: 0) {
                        ForEach(reports, id: \.id) { report in
                            Row(report: report, isFirst: report.id == reports.first?.id) {
                                onView(report)
                            }
                        }
                    }
                    
                } else {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                }
                
            case .failure(let error):
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                
            case nil:
                EmptyView()
            }
        }
    }
    
    private func fetchReports(delay: Bool = false) {
        Task {
            isFetchingReports = true
            
            defer {
                isFetchingReports = false
            }
            
            if delay {
                try await Task.sleep(for: .seconds(0.5))
            }
            
            if isRunningForPreviews {
                self.reportsResult = .success([.mock1, .mock2, .mock3])
                return
            }
            
            do {
                if let reportsResult, reportsResult.isFailure {
                    self.reportsResult = nil // Loading
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
                
            } catch {
                self.reportsResult = .failure(error)
            }
        }
    }
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success(_): true
        default: false
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .failure(_): true
        default: false
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
