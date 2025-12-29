import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import Auth

struct PastReportListView: View {
    var reports: [WSReportMeta]?
    var fetchDate: Date?
    var onView: (WSReportMeta) -> Void
    @Environment(API.self) var api
    
    var body: some View {
        bodyImpl()
            .onSceneBecomeActive {
                fetchReports()
            }
            .onReceive(api.eventHub.connectEvents) {
                print("UserReportsView: connect event")
                fetchReports()
            }
            
    }
    
    @ViewBuilder
    private func bodyImpl() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Past Spendings")
                .font(.system(size: 27, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let reports {
                if reports.count > 0 {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(reports, id: \.id) { report in
                            Row(report: report, isFirst: report.id == reports.first?.id) {
                                onView(report)
                            }
                        }
                        
                        Text("Data for the past 6 months is shown.")
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
            
//            if debugging {
//                Text("[D] Last Fetched: \(fetchDate?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
//                    .foregroundStyle(.secondary)
//                    .padding(.top, 12)
//            }
        }
    }
    
    private func fetchReports() {
        
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
        .onTapGesture {
            onView()
        }
    }
}

#Preview {
    ScrollView {
        PastReportListView(
            reports: [.mock1, .mock2, .mock3],
            onView: { _ in }
        )
        .padding()
    }
}
