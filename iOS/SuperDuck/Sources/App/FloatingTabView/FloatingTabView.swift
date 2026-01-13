import SwiftUI
import CommonUI

struct FloatingTabView<ID: Hashable>: View {
    @Binding var selection: ID
    var tabs: [FloatingTab<ID>]
    @State private var barHeight: CGFloat = 0
    @State private var safeAreaBottomInset: CGFloat = 0
    
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
            
            // Have to subtract safeAreaBottomInset because this value is meant for views
            // that do not ignore system safe area insets
            // The 0 case is likely for when keyboard is visible
            let floatingBarBottomInset = max(barHeight - safeAreaBottomInset, 0)
            
            ForEach(tabs, id: \.id) { tabItem in
                let selected = selection == tabItem.id
                
                tabItem.content()
                    .opacity(selected ? 1 : 0)
                    .transaction { $0.animation = nil }
                    .environment(\.isFloatingTabSelected, selected)
            }
            .environment(\._floatingTabBarBottomInset, floatingBarBottomInset)
            
            FloatingTabBar(
                selection: $selection,
                tabs: tabs
            )
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
                // print("! barHeight changed to \(newValue)")
                barHeight = newValue
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.bottom) { newValue in
                // print("! safeAreaInsets.bottom changed to \(newValue)")
                safeAreaBottomInset = newValue
            }
        }
    }
}

extension EnvironmentValues {
    /// Safe area bottom inset caused by floating tab bar.
    /// Note that this is meant for views that does not ignore built-in safe area insets (via `ignoresSafeAreaInset()`).
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
                },
                FloatingTab(id: 4, title: "Search", systemImage: "magnifyingglass") {
                    AnyView(ContentView(title: "Search"))
                },
                FloatingTab(id: 5, title: "Library", systemImage: "books.vertical") {
                    AnyView(ContentView(title: "Library"))
                },
                FloatingTab(id: 6, title: "Profile", systemImage: "person") {
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
