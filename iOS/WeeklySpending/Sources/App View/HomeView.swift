import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import AppUI

struct HomeView: View {
    // @AppStorage("App:cachedTemplateName") var cachedTemplateName: String = ""
    @State var presentingSettings = false
    var auth = Auth.shared
    @Environment(AppDefaults.self) private var appDefaults
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 36) {
                    bodyContent()
                }
                .padding()
            }
            .navigationTitle("Weekly Spending")
            .toolbar { toolbarContent() }
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
        let user: User? = {
            if isRunningForPreviews {
                .mock
            } else {
                auth.user
            }
        }()
        
        NewReportButton()
        
        if let user {
            UserReportsView(user: user) { reportMeta in
                print("Tapped \(reportMeta.id)")
            }            
        }
        
    }
}

#Preview {
    HomeView()
        .tint(.theme)
        .environment(AppDefaults())
}
