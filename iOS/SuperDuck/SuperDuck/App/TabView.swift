import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct TabView: View {
    @AppStorage("tabViewSelection") private var tabViewSelection = TabViewSelection.quiz
    @Bindable private var appDefaults = AppDefaults.shared
    
    var body: some View {
        @Bindable var appDefaults = appDefaults
        
        SwiftUI.TabView(selection: $tabViewSelection) {
            Tab("FOH Test", systemImage: "pencil.and.list.clipboard", value: .quiz) {
                QuizView()
            }
                        
            Tab("Weekly Spending", systemImage: "australiandollarsign", value: .weeklySpending) {
                WeeklySpendingView()
            }
                        
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
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
}
