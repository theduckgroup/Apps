import SwiftUI
import CommonUI

/// Component used by `FloatingTabView`.
struct FloatingTabBar<ID: Hashable>: View {
    @Binding var selection: ID
    var tabItems: [FloatingTabItem<ID>]
    @Namespace private var tabNamespace
    
    init(
        selection: Binding<ID>,
        tabItems: [FloatingTabItem<ID>],
    ) {
        self._selection = selection
        self.tabItems = tabItems
    }
    
    public var body: some View {
        // ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(tabItems, id: \.id) { tab in
                    tabButton(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(4)
        // }
        .modified {
            if #available(iOS 26, *) {
                // $0.glassEffect(.regular, in: ConcentricRectangle(corners: .concentric(minimum: .fixed(15)), isUniform: true))
                $0.glassEffect(.regular, in: .capsule)
            } else {
                $0
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    private func tabButton(for tab: FloatingTabItem<ID>) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = tab.id
            }
        } label: {
            ZStack {
                let selected = selection == tab.id
                
                if selected {
                    Capsule()
                        .fill(Color(UIColor.systemGray5))
                        .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
                }
                
                VStack(spacing: 3) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 24, weight: .medium))
//                        .symbolEffect(
//                            .bounce.down.byLayer,
//                            value: selected
//                        )
                        .frame(height: 28)
                    
                    Text(tab.title)
                        .font(.system(size: 11, weight: .medium))
                        .fixedSize()
                }
                .modified {
                    if selected {
                        $0.foregroundStyle(.tint)
                    } else {
                        $0.foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

/// Custom button style for tab buttons with subtle press effect
private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
