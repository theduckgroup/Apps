import Foundation
import SwiftUI
import CommonUI

struct TabView: View {
    @AppStorage("tabViewSelection") private var tabViewSelection = TabViewItem.inventory
    @Environment(AppDefaults.self) private var appDefaults
    @AppStorage("tabViewCustomization:2") private var tabViewCustomization = TabViewCustomization()
    @State private var barHeight: CGFloat = 0
    
    var body: some View {
        FloatingTabView(
            selection: $tabViewSelection,
            tabItems: tabs
        )
    }
    
    private var tabs: [FloatingTabItem<TabViewItem>] {
        var tabs: [FloatingTabItem<TabViewItem>] = [
            .init(id: .quiz, title: "FOH Test", systemImage: "questionmark.text.page.fill") {
                AnyView(QuizAppView())
            },
            .init(id: .weeklySpending, title: "Weekly Spending", systemImage: "wallet.bifold.fill") {
                AnyView(WeeklySpendingAppView())
            },
            .init(id: .inventory, title: "Inventory", systemImage: "square.stack.3d.up.fill") {
                AnyView(InventoryAppView())
            },
            .init(id: .nakedBlendCalc, title: "Naked Blend", systemImage: "plusminus.circle.fill") {
                AnyView(NakedBlendCalcAppView())
            },
            .init(id: .settings, title: "Settings", systemImage: "gearshape.fill") {
                AnyView(SettingsView())
            },
        ]
        
        tabs = tabs.filter {
            !appDefaults.hiddenTabViewItems.contains($0.id)
        }
        
        return tabs
    }
}

#Preview("TabView") {
    TabView()
        .applyAppDefaultsStyling()
        .previewEnvironment()
}

#Preview("Native") {
    @Previewable @State var selection = 0
    
    SwiftUI.TabView(selection: $selection) {
        Tab("FOH Test", systemImage: "questionmark.text.page.fill", value: 0) {
            QuizAppView()
        }
        Tab("Weekly Spending", systemImage: "wallet.bifold.fill", value: 1) {
            QuizAppView()
        }
        Tab("Inventory", systemImage: "square.stack.3d.up.fill", value: 2) {
            QuizAppView()
        }
        Tab("Settings", systemImage: "gearshape.fill", value: 3) {
            QuizAppView()
        }
    }
    .applyAppDefaultsStyling()
    .previewEnvironment()
}
