import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct NewReportButton: View {
    @State var templateResult: Result<WSTemplate, Error>?
    @State var isFetchingTemplate = false
    @State var fetchTemplateTask: Task<Void, Never>?
    @State var lastFetchedTemplate: Date?
    @State var ps = PresentationState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading) {
            fetchStatusView()
            
            if templateResult?.value == nil && !isFetchingTemplate {
                // Don't show button
            } else {
                button()
            }
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
    private func fetchStatusView() -> some View {
        if !isFetchingTemplate, let templateResult, case .failure(let error) = templateResult {
            VStack(alignment: .leading) {
                Text(formatError(error))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                
                Button {
                    self.templateResult = nil
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
    
    @ViewBuilder
    private func button() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            let template = templateResult?.value
            
            Button {
                if let template {
                    ps.presentFullScreenCover {
                        let user = WSReport.User(from: Auth.shared.user!)
                        ReportView(template: template, user: user)
                    }
                }
                
            } label: {
                Group {
                    if template == nil && isFetchingTemplate {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.secondary)
                            
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Label("New Spending", systemImage: "plus")
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(template == nil)
            
            if debugging {
                Text("[D] Last Fetched: \(lastFetchedTemplate?.ISO8601Format(.iso8601(timeZone: .current)), default: "Never")")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func fetchTemplate(delay: Bool = false) {
        fetchTemplateTask?.cancel()
        
        fetchTemplateTask = Task {
            isFetchingTemplate = true
            
            defer {
                isFetchingTemplate = false
            }
            
            do {
                if delay {
                    try await Task.sleep(for: .seconds(1))
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
                
                self.templateResult = .success(template)
                // self.cachedTemplateName = template.name
                
                lastFetchedTemplate = Date()
                
            } catch {
                
                logger.error("Unable to fetch template: \(error)")
                self.templateResult = .failure(error)
            }
        }
    }
}
