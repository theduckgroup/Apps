import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import AppUI
import Auth

struct HomeView: View {
    var user: User

    @State private var template: WSTemplate?
    @State private var templateError: Error?
    @State private var templateFetchDate: Date?
    @State private var isFetchingTemplate = false
    @State private var fetchTemplateTask: Task<Void, Never>?
    
    @State private var reports: [WSReportMeta]?
    @State private var reportsError: Error?
    @State private var reportsFetchDate: Date?
    @State private var isFetchingReports = false
    @State private var fetchReportsTask: Task<Void, Never>?
    
    @State var presentingSettings = false
    @Environment(AppDefaults.self) private var appDefaults
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Weekly Spending")
                .toolbar { toolbarContent() }
        }
        .onFirstAppear {
            fetchTemplate()
            fetchReports()
        }
        .onSceneBecomeActive {
            fetchTemplate()
            fetchReports()
        }
        .onReceive(EventHub.shared.connectEvents) {
            fetchTemplate()
            fetchReports()
        }
        .onReceive(EventHub.shared.templatesChangeEvents) {
            fetchTemplate()
        }
        .onReceive(EventHub.shared.userReportsChangeEvents(userID: user.idString)) {
            fetchReports()
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
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 36) {
                NewReportButton(template: template)
                
                UserReportsView(reports: reports) { reportMeta in
                    print("Tapped \(reportMeta.id)")
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            loadingView()
        }
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        if isFetchingTemplate || isFetchingReports {
            HStack {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
                
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(.regularMaterial)
            }
            
        } else if let error = templateError ?? reportsError {
            VStack(alignment: .leading) {
                Text(formatError(error))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Retry") {
                    fetchTemplate()
                    fetchReports()
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
                    .fill(.regularMaterial)
            }
            .padding()
        }
    }
    
    private func fetchTemplate() {
        fetchTemplateTask?.cancel()
        
        fetchTemplateTask = Task {
            do {
                isFetchingTemplate = true
                templateError = nil
                
                if debugging {
                    // try await Task.sleep(for: .seconds(0.5))
                }
                    
                let template = try await {
                    if isRunningForPreviews {
                        return try await API.shared.mockTemplate()
                    }
                    
                    return try await API.shared.template(code: "WEEKLY_SPENDING")
                }()
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                self.template = template
                self.templateError = nil
                self.templateFetchDate = Date()
                self.isFetchingTemplate = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                self.templateError = error
                self.isFetchingTemplate = false
            }
        }
    }
    
    private func fetchReports() {
        fetchReportsTask?.cancel()
        
        fetchReportsTask = Task {
            do {
                isFetchingReports = true
                reportsError = nil
                
                if debugging {
                    // try await Task.sleep(for: .seconds(0.5))
                }
                
                
                var fetchedReports: [WSReportMeta] = try await {
                    if isRunningForPreviews {
                        return [.mock1, .mock2, .mock3]
                        throw GenericError("Cupidatat est sit fugiat consectetur tempor fugiat culpa.")
                    }
                        
                    return try await API.shared.userReports(userID: user.id.uuidString)
                }()
                
                fetchedReports.sort(on: \.date, ascending: false)
                
                if let reports, reports.count > 0 {
                    withAnimation {
                        self.reports = fetchedReports
                    }
                } else {
                    self.reports = fetchedReports
                }
                
                self.reportsError = nil
                self.reportsFetchDate = Date()
                self.isFetchingReports = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                                
                self.reportsError = error
                self.isFetchingReports = false
            }
        }
    }
}

#Preview {
    HomeView(user: .mock)
        .tint(.theme)
        .environment(AppDefaults())
}
