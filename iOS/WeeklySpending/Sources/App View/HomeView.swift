import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import AppUI

struct HomeView: View {
    // @AppStorage("App:cachedTemplateName") var cachedTemplateName: String = ""
    @State var templateResult: Result<WSTemplate, Error>?
    @State var error: Error?
    @State var isFetching = false
    @State var fetchTask: Task<Void, Never>?
    @State var ps = PresentationState()
    @State var presentingSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(AppDefaults.self) private var appDefaults
    
    var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Weekly Spending")
                .toolbar { toolbarContent() }
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
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                presentingSettings = true
                
            } label: {
                Image(systemName: "person.fill")
            }
            .popover(isPresented: $presentingSettings) {
                @Bindable var appDefaults = appDefaults

                SettingsView(
                    colorSchemeOverride: $appDefaults.colorSchemeOverride,
                    accentColor: $appDefaults.accentColor,
                    containerHorizontalSizeClass: horizontalSizeClass
                )
            }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        VStack(alignment: .leading) {
            VStack(spacing: 15) {
//                if !cachedTemplateName.isEmpty {
//                    Text(cachedTemplateName)
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                }
                
                let template: WSTemplate? =
                    if let templateResult, case .success(let template) = templateResult {
                        template
                    } else {
                        nil
                    }
                
//                Button {
//                    if let template {
//                        ps.presentFullScreenCover {
//                            ReportView(template: template)
//                        }
//                    }
//                } label: {
//                    Text("Submit")
//                        .padding(.horizontal, 9)
//                }
//                .buttonStyle(.paperProminent)
//                .disabled(template == nil)
                
                Button {
                    if let template {
                        ps.presentFullScreenCover {
                            let user = WSReport.User(from: Auth.shared.user!)
                            ReportView(template: template, user: user)
                        }
                    }
                } label: {
                    Label("New Spending", systemImage: "plus")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .disabled(template == nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .overlay(alignment: .bottom) {
            if isFetching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 30)
                
            } else if let templateResult, case .failure(let error) = templateResult {
                VStack(alignment: .leading) {
                    Text(formatError(error))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Retry") {
                        fetchTemplate(delay: true)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .fixedSize(horizontal: false, vertical: false)
                .padding()
                .frame(width: horizontalSizeClass == .regular ? 570 : nil)
                .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemFill))
                }
                .padding()
            }
        }
    }
    
    private func fetchTemplate(delay: Bool = false) {
        fetchTask?.cancel()
        
        fetchTask = Task {
            isFetching = true
            
            do {
                if delay {
                    try await Task.sleep(for: .seconds(1))
                }
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                let template = try await {
                    if isRunningForPreviews {
                        return try await API.shared.mockTemplate()
                    }
                    
                    return try await API.shared.template(code: "WEEKLY_SPENDING")
                }()

                self.templateResult = .success(template)
                // self.cachedTemplateName = template.name
                
                isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                isFetching = false
                
                logger.error("Unable to load template: \(error)")
                self.templateResult = .failure(error)
            }
        }
    }
}

#Preview {
    HomeView()
        .tint(.red)
        .environment(AppDefaults())
}
