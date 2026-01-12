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
            tabItems: [
                .init(id: TabViewItem.quiz, title: "FOH Test", systemImage: "questionmark.text.page.fill") {
                    AnyView(QuizAppView())
                },
                .init(id: TabViewItem.inventory, title: "Inventory", systemImage: "books.vertical") {
                    AnyView(QuizAppView())
                }
            ]
        )
    }
    
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            SwiftUI.TabView(selection: $tabViewSelection) {
//                let hiddenItems = appDefaults.hiddenTabViewItems
//                
//                if !hiddenItems.contains(.quiz) {
//                    // pencil.and.list.clipboard
//                    // list.clipboard.fill
//                    // append.page.fill
//                    // quiz-app
//                    Tab("FOH Test", systemImage: "questionmark.text.page.fill", value: .quiz) {
//                        QuizAppView()
//                            .onAppear {
//                                print("! FOH appear")
//                            }
//                    }
//                    // .customizationID("quiz")
//                }
//                
//                if !hiddenItems.contains(.weeklySpending) {
//                    Tab("Weekly Spending", systemImage: "wallet.bifold", value: .weeklySpending) {
//                        WeeklySpendingAppView()
//                            .onAppear {
//                                print("! WS appear")
//                            }
//                    }
//                    // .customizationID("weeklySpending")
//                }
//                
//                if !hiddenItems.contains(.inventory) {
//                    // list.triangle
//                    // list.bullet.clipboard.fill
//                    Tab("Inventory", image: "inventory-app", value: .inventory) {
//                        InventoryAppView()
//                            .safeAreaInset(edge: .bottom) {
//                                Rectangle()
//                                    .fill(Color.clear)
//                                    .frame(width: 30, height: 150)
//                            }
//                            .onAppear {
//                                print("! Inventory appear")
//                            }
//                    }
//                    // .customizationID("inventory")
//                }
//                
//                Tab("Settings", systemImage: "gearshape", value: .settings) {
//                    GeometryReader { geometryProxy in
//                        let _ = print("geometryProxy sainsets = \(geometryProxy.safeAreaInsets)")
//                        let _ = print("barheight = \(barHeight)")
//                        SettingsView()
//                            .safeAreaInset(edge: .bottom) {
//                                Rectangle()
//                                    .fill(Color.clear)
//                                    .frame(width: 30, height: 60)
//                            }
//                            .onAppear {
//                                print("! Settings appear")
//                            }
//                        // .ignoresSafeArea(edges: [])
//                            // .contentMargins(.bottom, barHeight - geometryProxy.safeAreaInsets.bottom, for: .scrollContent)
//                    }
//                }
//                // .customizationID("settings")
//            }
//            // .tabViewStyle(.page(indexDisplayMode: .never))
//            .ignoresSafeArea(edges: [.top, .bottom])
//            .onAppear {
//                UITabBar.appearance().isHidden = true
//            }
//           
//            GeometryReader { geometryProxy in
//                ZStack(alignment: .bottom) {
//                    Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
//                    
//                    FloatingTabView(
//                        selection: $tabViewSelection,
//                        tabItems: [
//                            .init(id: .quiz, title: "FOH Test", systemImage: "questionmark.text.page.fill"),
//                            .init(id: .weeklySpending, title: "Weekly Spending", systemImage: "wallet.bifold"),
//                            .init(id: .inventory, title: "Inventory", systemImage: "books.vertical"),
//                            .init(id: .settings, title: "Settings", systemImage: "gearshape"),
//                        ]
//                    )
//                    // .frame(maxWidth: geometryProxy.size.width)
//                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
//                        print("Geometry changed to \(newValue)")
//                        barHeight = newValue - geometryProxy.safeAreaInsets.bottom
//                    }
//                }
//                .ignoresSafeArea(edges: .bottom)
//                .overlay { Text("\(barHeight)") } // Need this or barHeight stays 0!
//            }
//        }
//    }
}

#Preview {
    TabView()
        .applyAppDefaultsStyling()
        .previewEnvironment()
}
