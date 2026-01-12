import SwiftUI
import CommonUI

/// Component used by `FloatingTabView`.
struct FloatingTabBar<ID: Hashable>: View {
    @Binding var selection: ID
    var tabItems: [FloatingTabItem<ID>]
    @State private var scrollViewWidth: CGFloat = 0
    @State private var buttonFrames: [ID: CGRect] = [:]
    @State private var selectionIndicatorID: ID // ID for selection indicator (gray background capsule)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(
        selection: Binding<ID>,
        tabItems: [FloatingTabItem<ID>],
    ) {
        self._selection = selection
        self._selectionIndicatorID = .init(wrappedValue: selection.wrappedValue)
        self.tabItems = tabItems
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: buttonSpacing) {
                ForEach(tabItems, id: \.id) { tab in
                    tabButton(for: tab, isFirst: tab.id == tabItems[0].id, isLast: tab.id == tabItems.last!.id)
                        .frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(3)
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
                    // $0.glassEffect(.regular, in: .rect(cornerRadius: 32))
                } else {
                    $0
                }
            }
            .padding(.horizontal, edgePadding)
            .frame(minWidth: scrollViewWidth, alignment: .center)
        }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) {
            self.scrollViewWidth = $0
        }
        .padding(.bottom, edgePadding)
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
                        .frame(height: 28)
                        
                    Text(tab.title)
                        .font(.system(size: 13, weight: .medium).leading(.tight))
                        // .frame(maxWidth: 28 * 2, alignment: .center)
                        .multilineTextAlignment(.center)
                        .fixedSize()
                }
                .modified {
                    if selected {
                        $0.foregroundStyle(.tint)
                    } else {
                        $0.foregroundStyle(.primary)
                    }
                }
                // .padding(.vertical, 12)
                .frame(height: barHeight)
                .padding(.horizontal, buttonInnerPadding)
                .padding(.leading, isFirst ? buttonExtraPadding : 0)
                .padding(.trailing, isLast ? buttonExtraPadding : 0)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("buttonHStack"))}, action: { newValue in
                    buttonFrames[tab.id] = newValue
                })
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
    
    private var barHeight: CGFloat {
        // Rationale for bigger height on iPhone: to avoid the app switcher area while scrolling
        horizontalSizeClass == .regular ? 64 : 72
    }
    
    private var edgePadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 18
    }
    
    private var buttonSpacing: CGFloat {
        horizontalSizeClass == .regular ? 6 : 0
    }
    
    private var buttonInnerPadding: CGFloat {
        horizontalSizeClass == .regular ? 12 : 12
    }
    
    private var buttonExtraPadding: CGFloat {
        horizontalSizeClass == .regular ? 12 : 12
    }
}

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
