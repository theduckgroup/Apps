import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct NewReportButton: View {
    var template: WSTemplate?
    var fetchDate: Date?
    @State var ps = PresentationState()
    @Environment(Auth.self) var auth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            button()
            
//            if debugging {
//                Text("[D] Last Fetched: \(fetchDate?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
//                    .foregroundStyle(.secondary)
//            }
        }
        .presentations(ps)
    }
    
    @ViewBuilder
    private func button() -> some View {
        HStack(spacing: 15) {
            Button {
                if let template {
                    ps.presentFullScreenCover {
                        let user = WSReport.User(from: auth.user!)
                        NewReportView(template: template, user: user)
                    }
                }
                
            } label: {
                Label("New Spending", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(template == nil)
        }
    }
}
