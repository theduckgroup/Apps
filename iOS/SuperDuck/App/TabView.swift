import Foundation
import SwiftUI
import AppShared
import Backend
import QuizApp
import WeeklySpendingApp
import CommonUI

struct TabView: View {
    @AppStorage("tabViewSelection") private var tabViewSelection = TabViewSelection.quiz
    
    var body: some View {
        SwiftUI.TabView(selection: $tabViewSelection) {
            // pencil.and.list.clipboard
            Tab("FOH Test", systemImage: "list.clipboard.fill", value: .quiz) {
                QuizApp.RootView()
                    .nonProdWarningOverlay()
            }

            Tab("Weekly Spending", systemImage: "wallet.bifold", value: .weeklySpending) {
                WeeklySpendingApp.RootView()
                    .nonProdWarningOverlay()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
                    .nonProdWarningOverlay()
            }
        }
                
//        TabView(selection: $selectedTab) {
//            @Bindable var appDefaults = appDefaults
//            
//            QuizView()
//                .tabItem {
//                    Label("FOH Test", systemImage: "house")
//                }
//                .tag(0)
//            
//            WeeklySpendingView()
//                .tabItem {
//                    Label("Search", systemImage: "magnifyingglass")
//                }
//                .tag(1)
//            
//            SettingsView(colorSchemeOverride: $appDefaults.colorSchemeOverride, accentColor: $appDefaults.accentColor, containerHorizontalSizeClass: .regular)
//                .tabItem {
//                    Label("Settings", systemImage: "gear")
//                }
//                .tag(2)
//        }
    }
}

extension TabView {
    enum TabViewSelection: String, Hashable {
        case quiz
        case weeklySpending
        case settings
    }
}

#Preview {
    TabView()
        .previewEnvironment()
}
