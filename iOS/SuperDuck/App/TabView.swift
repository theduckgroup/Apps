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
            Tab("FOH Test", systemImage: "pencil.and.list.clipboard", value: .quiz) {
                QuizApp.RootView()
            }
                        
            Tab("Weekly Spending", systemImage: "australiandollarsign", value: .weeklySpending) {
                WeeklySpendingApp.RootView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .environment(API.shared)
        
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
        .withMockEnvironment()
}
