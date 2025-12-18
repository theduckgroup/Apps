import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct NewReportButton: View {
    @State var template: WSTemplate?
    @State var error: Error?
    @State var isFetching = false
    @State var lastFetchDate: Date?
    @State var fetchTask: Task<Void, Never>?
    @State var ps = PresentationState()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            button()
            
            if debugging {
                Text("[D] Last Fetched: \(lastFetchDate?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
                    .foregroundStyle(.secondary)
            }
            
            errorView()
        }
        .presentations(ps)
        .onSceneBecomeActive {
            fetchTemplate()
        }
        .onReceive(EventHub.shared.connectEvents) {
            fetchTemplate()
        }
        .onReceive(EventHub.shared.templatesChangeEvents) {
            fetchTemplate()
        }
    }
    
    @ViewBuilder
    private func button() -> some View {
        HStack(spacing: 15) {
            Button {
                if let template {
                    ps.presentFullScreenCover {
                        let user = WSReport.User(from: Auth.shared.user!)
                        ReportView(template: template, user: user)
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
            
            if template == nil && isFetching {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func errorView() -> some View {
        if !isFetching, let error {
            VStack(alignment: .leading) {
                Text(formatError(error))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                
                Button {
                    fetchTemplate(delay: true)
                    
                } label: {
                    Text("Retry")
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.bordered)
            }
            .fixedSize(horizontal: false, vertical: false)
        }
    }
    
    private func fetchTemplate(delay: Bool = false) {
        fetchTask?.cancel()
        
        fetchTask = Task {
            do {
                isFetching = true
                error = nil
                
                defer {
                    isFetching = false
                }
                    
                if delay {
                    try await Task.sleep(for: .seconds(0.5))
                }
                
                let template = try await {
                    if isRunningForPreviews {
                        try await Task.sleep(for: .seconds(1))
                        return try await API.shared.mockTemplate()
                    }
                    
                    return try await API.shared.template(code: "WEEKLY_SPENDING")
                }()
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                self.template = template
                self.error = nil
                
                lastFetchDate = Date()
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                self.error = error
            }
        }
    }
}
