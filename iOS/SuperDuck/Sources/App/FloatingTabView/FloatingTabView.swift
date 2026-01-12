import SwiftUI
import CommonUI

struct FloatingTabView<ID: Hashable>: View {
    @Binding var selection: ID
    var tabs: [FloatingTab<ID>]
    @State private var barHeight: CGFloat = 0
    
    init(
        selection: Binding<ID>,
        tabs: [FloatingTab<ID>],
    ) {
        self._selection = selection
        self.tabs = tabs
    }
    
    var body: some View {
        ZStack {
            // Can also use SwiftUI TabView but couldn't make it work perfectly:
            // - tabViewStyle(.page(indexDisplayMode: .never)): Broken nav title
            // - UITabBar.appearance().isHidden = true: does not work on iPad where the tab bar is at the top
            
            ForEach(tabs, id: \.id) { tabItem in
                let selected = selection == tabItem.id
                
                tabItem.content()
                    .opacity(selected ? 1 : 0)
                    .transaction { $0.animation = nil }
                    .environment(\._floatingTabBarBottomInset, barHeight)
                    .environment(\.floatingTabSelected, selected)
            }
           
            // GeometryReader is used both for getting the safe area insets
            // and making sure that the tab bar does not exceed the screen width
            
            GeometryReader { geometryProxy in
                FloatingTabBar(
                    selection: $selection,
                    tabs: tabs
                )
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
                    // Note: geometryProxy.safeAreaInsets doesn't report keyboard insets
                    // Not a big problem
                    
                    // print("! barHeight = \(newValue)")
                    // print("! safeAreaInsets = \(geometryProxy.safeAreaInsets)")
                    barHeight = newValue - geometryProxy.safeAreaInsets.bottom
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
            
//            SwiftUI.TabView(selection: $selection) {
//                ForEach(tab, id: \.id) { tab in
//                    Tab(tab.title, systemImage: tab.systemImage, value: tab.id) {
//                        tab.content()
//                    }
//                }
//            }
//            .tabViewStyle(.page(indexDisplayMode: .never))
//            .ignoresSafeArea(edges: [.top, .bottom])
//            .onAppear {
//                UITabBar.appearance().isHidden = true
//            }
        }
    }
}

extension EnvironmentValues {
    @Entry var _floatingTabBarBottomInset: CGFloat = 0
}

/// Custom button style for tab buttons with subtle press effect
private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    PreviewView()
}

private struct PreviewView: View {
    @State var selectedTab = 0
    @State var showingDetail = false
    
    var body: some View {
        FloatingTabView(
            selection: $selectedTab,
            tabs: [
                FloatingTab(id: 0, title: "Home", systemImage: "house") {
                    AnyView(ContentView(title: "Home"))
                },
                FloatingTab(id: 1, title: "Search", systemImage: "magnifyingglass") {
                    AnyView(ContentView(title: "Search"))
                },
                FloatingTab(id: 2, title: "Library", systemImage: "books.vertical") {
                    AnyView(ContentView(title: "Library"))
                },
                FloatingTab(id: 3, title: "Profile", systemImage: "person") {
                    AnyView(ContentView(title: "Profile"))
                }
            ]
        )
        .tint(Color.theme)
    }
    
    struct ContentView: View {
        var title: String
        @State var showingDetail = false
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .center) {
                        Button("Detail") {
                            showingDetail = true
                        }
                        
                        ForEach(1..<25) { _ in
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 60)
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Text("Extra stuffs")
                        .font(.callout)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.yellow)
                        }
                }
                .floatingTabBarSafeAreaInset()
                .navigationTitle(title)
                .navigationDestination(isPresented: $showingDetail) {
                    ScrollView {
                        ForEach(1..<25) { _ in
                            Rectangle()
                                .fill(Color.brown)
                                .frame(height: 60)
                        }
                        .padding()
                    }
                    .floatingTabBarSafeAreaInset()
                }
            }
        }
    }
}
