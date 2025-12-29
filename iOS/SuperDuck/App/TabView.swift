import Foundation
import SwiftUI
import AppShared
import Backend
import InventoryApp
import QuizApp
import WeeklySpendingApp
import CommonUI

struct TabView: View {
    @AppStorage("tabViewSelection") private var tabViewSelection = TabViewSelection.quiz
    @State var inventoryAppDefaults = InventoryApp.Defaults()
    
    var body: some View {
        SwiftUI.TabView(selection: $tabViewSelection) {
            // pencil.and.list.clipboard
            // list.clipboard.fill
            Tab("FOH Test", systemImage: "append.page.fill", value: .quiz) {
                QuizApp.RootView()
            }

            Tab("Weekly Spending", systemImage: "wallet.bifold", value: .weeklySpending) {
                WeeklySpendingApp.RootView()
            }
            
            // list.triangle
            Tab("Inventory", systemImage: "list.bullet.clipboard.fill", value: .inventory) {
                InventoryApp.RootView()
                    .environment(inventoryAppDefaults)
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
                    .environment(inventoryAppDefaults)
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
        case inventory
        case settings
    }
}

#Preview {
    TabView()
        .applyAppDefaultsStyling()
        .previewEnvironment()
}
