import Foundation
import SwiftUI
import AppModule
import Backend
import InventoryApp
import QuizApp
import WeeklySpendingApp
import CommonUI

struct TabView: View {
    @AppStorage("tabViewSelection") private var tabViewSelection = TabViewItem.quiz
    @Environment(AppDefaults.self) private var appDefaults
    @AppStorage("tabViewCustomization:2") private var tabViewCustomization = TabViewCustomization()
    
    var body: some View {
        SwiftUI.TabView(selection: $tabViewSelection) {
            let hiddenItems = appDefaults.hiddenTabViewItems
            
            if !hiddenItems.contains(.quiz) {
                // pencil.and.list.clipboard
                // list.clipboard.fill
                // append.page.fill
                // quiz-app
                Tab("FOH Test", systemImage: "questionmark.text.page.fill", value: .quiz) {
                    QuizAppView()
                }
                // .customizationID("quiz")
            }
            
            if !hiddenItems.contains(.weeklySpending) {
                Tab("Weekly Spending", systemImage: "wallet.bifold", value: .weeklySpending) {
                    WeeklySpendingAppView()
                }
                // .customizationID("weeklySpending")
            }
            
            if !hiddenItems.contains(.inventory) {
                // list.triangle
                // list.bullet.clipboard.fill
                Tab("Inventory", image: "inventory-app", value: .inventory) {
                    InventoryAppView()
                }
                // .customizationID("inventory")
            }
            
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
            // .customizationID("settings")
        }
//        .tabViewStyle(.sidebarAdaptable)
//        .modified {
//            if #available(iOS 26, *) {
//                $0.tabBarMinimizeBehavior(.onScrollDown)
//            } else {
//                $0
//            }
//        }
//        .tabViewCustomization($tabViewCustomization)
    }
}

#Preview {
    TabView()
        .applyAppDefaultsStyling()
        .previewEnvironment()
}
