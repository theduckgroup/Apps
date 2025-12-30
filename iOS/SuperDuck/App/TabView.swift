import Foundation
import SwiftUI
import AppModule
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
            // append.page.fill
            // quiz-app
            Tab("FOH Test", systemImage: "questionmark.text.page.fill", value: .quiz) {
                QuizApp.RootView()
            }

            Tab("Weekly Spending", systemImage: "wallet.bifold", value: .weeklySpending) {
                WeeklySpendingApp.RootView()
            }
            
            // list.triangle
            // list.bullet.clipboard.fill
            Tab("Inventory", image: "inventory-app", value: .inventory) {
                InventoryApp.RootView()
                    .environment(inventoryAppDefaults)
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
                    .environment(inventoryAppDefaults)
            }
        }
          
        /*
        SwiftUI.TabView(selection: $tabViewSelection) {
            QuizApp.RootView()
                .tabItem {
                    Label("FOH Test", image: "quiz-app")
                }
                .tag(TabViewSelection.quiz)
            
            WeeklySpendingApp.RootView()
                .tabItem {
                    Label("Inventory", image: "inventory-app")
                }
                .tag(TabViewSelection.inventory)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(TabViewSelection.settings)
        }
        */
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
