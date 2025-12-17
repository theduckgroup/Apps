import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct NewReportButton: View {
    @State var templateResult: Result<WSTemplate, Error>?
    @State var isFetchingTemplate = false
    @State var fetchTemplateTask: Task<Void, Never>?
    @State var lastFetchTemplate: Date?
    @State var ps = PresentationState()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading) {
            fetchStatusView()
            
            if let templateResult, templateResult.isFailure {
                // Don't show button
            } else {
                button()
            }
        }
        .presentations(ps)
        .onFirstAppear {
            fetchTemplate()
        }
        .onReceive(EventHub.shared.templatesChanged) {
            fetchTemplate()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                fetchTemplate()
            }
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
            let template: WSTemplate? = {
                if let templateResult, case .success(let template) = templateResult {
                    template
                } else {
                    nil
                }
            }()
            
            Button {
                if let template {
                    ps.presentFullScreenCover {
                        let user = WSReport.User(from: Auth.shared.user!)
                        ReportView(template: template, user: user)
                    }
                }
                
            } label: {
                Group {
                    if !isFetchingTemplate {
                        Label("New Spending", systemImage: "plus")
                            .fontWeight(.semibold)
                        
                    } else {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.secondary)
                            
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(template == nil || isFetchingTemplate)
            
            if debugging {
                // Text("Last Fetched: \(lastFetch?.ISO8601Format(), default: "Never")")
            }
        }
    }
    
    private func fetchTemplate(delay: Bool = false) {
        fetchTemplateTask?.cancel()
        
        fetchTemplateTask = Task {
            isFetchingTemplate = true
            
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
                
                isFetchingTemplate = false
                lastFetchTemplate = Date()
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                isFetchingTemplate = false
                
                logger.error("Unable to load template: \(error)")
                self.templateResult = .failure(error)
            }
        }
    }
}
