import SwiftUI
import CommonUI

/// Component used by `FloatingTabView`.
struct FloatingTabBar<ID: Hashable>: View {
    @Binding var selection: ID
    var tabItems: [FloatingTabItem<ID>]
    @State private var scrollViewWidth: CGFloat = 0
    @State private var buttonFrames: [ID: CGRect] = [:]
    @State private var selectionIndicatorID: ID // ID for selection indicator (gray background capsule)
    private let buttonExtraPadding: CGFloat = 12
    @Namespace private var tabNamespace
    
    init(
        selection: Binding<ID>,
        tabItems: [FloatingTabItem<ID>],
    ) {
        self._selection = selection
        self._selectionIndicatorID = .init(wrappedValue: selection.wrappedValue)
        self.tabItems = tabItems
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tabItems, id: \.id) { tab in
                    tabButton(for: tab, isFirst: tab.id == tabItems[0].id, isLast: tab.id == tabItems.last!.id)
                        .frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(4)
            .coordinateSpace(.named("buttonHStack"))
            .background(alignment: .topLeading) {
                Group {
                    let frame = buttonFrames[selectionIndicatorID]
                    
                    if let frame {
                        let isFirst = selectionIndicatorID == tabItems.first?.id
                        let isLast = selectionIndicatorID == tabItems.last?.id
                        let minX = frame.minX - (isFirst ? 0 : buttonExtraPadding)
                        let maxX = frame.maxX + (isLast ? 0 : buttonExtraPadding)
                        
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .offset(x: minX, y: frame.minY)
                            .frame(width: maxX - minX, height: frame.height)
                    }
                }
            }
            .modified {
                if #available(iOS 26, *) {
                    // $0.glassEffect(.regular, in: ConcentricRectangle(corners: .concentric(minimum: .fixed(15)), isUniform: true))
                    $0.glassEffect(.regular, in: .capsule)
                } else {
                    $0
                }
            }
            .padding(.horizontal, 24)
            .frame(minWidth: scrollViewWidth, alignment: .center)
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) {
            self.scrollViewWidth = $0
        }
        .padding(.bottom, 24)
        .onChange(of: selection) {
            withAnimation(.spring(duration: 0.15)) {
                selectionIndicatorID = selection
            }
        }
    }
    
    private func tabButton(for tab: FloatingTabItem<ID>, isFirst: Bool, isLast: Bool) -> some View {
        Button {
            withAnimation(.spring(duration: 0.1)) {
                selection = tab.id
            }
        } label: {
            ZStack {
                let selected = selection == tab.id
               
                VStack(spacing: 3) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 22, weight: .medium))
//                        .symbolEffect(
//                            .bounce.down.byLayer,
//                            value: selected
//                        )
                        .frame(height: 28)
                    
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium))
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
                .padding(.horizontal, 12)
                .padding(.leading, isFirst ? buttonExtraPadding : 0)
                .padding(.trailing, isLast ? buttonExtraPadding : 0)
//                selectionExtraPadding
//                    .padding(.leading, isFirst ? 24 : 12)
//                .padding(.trailing, isLast ? 24 : 12)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("buttonHStack"))}, action: { newValue in
                    print("Button frame = \(newValue)")
                    buttonFrames[tab.id] = newValue
                })
//                .background {
//                    // if selected {
//                        Capsule()
//                            .fill(Color(UIColor.systemGray5))
//                            // .matchedGeometryEffect(id: "selectedTab", in: tabNamespace)
//                    // }
//                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
