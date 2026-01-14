import SwiftUI
import CommonUI

/// Component used by `FloatingTabView`.
struct FloatingTabBar<ID: Hashable>: View {
    @Binding var selection: ID
    var tabs: [FloatingTab<ID>]
    @State private var scrollViewWidth: CGFloat = 0
    @State private var scrollPosition = ScrollPosition(idType: ID.self)
    @State private var buttonFrames: [ID: CGRect] = [:]
    @State private var selectionIndicatorID: ID // ID for selection indicator (gray background capsule)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(
        selection: Binding<ID>,
        tabs: [FloatingTab<ID>],
    ) {
        self._selection = selection
        self._selectionIndicatorID = .init(wrappedValue: selection.wrappedValue)
        self.tabs = tabs
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: buttonSpacing) {
                ForEach(tabs, id: \.id) { tab in
                    tabButton(for: tab, isFirst: tab.id == tabs[0].id, isLast: tab.id == tabs.last!.id)
                        .id(tab.id)
                        .frame(maxWidth: .infinity)
                }
            }
            .scrollTargetLayout()
            .fixedSize(horizontal: true, vertical: true)
            .padding(3)
            .coordinateSpace(.named("buttonHStack"))
            .background(alignment: .topLeading) {
                Group {
                    if let frame = buttonFrames[selectionIndicatorID] {
                        let isFirst = selectionIndicatorID == tabs.first?.id
                        let isLast = selectionIndicatorID == tabs.last?.id
                        let minX = frame.minX - (isFirst ? 0 : buttonSelectionPadding)
                        let maxX = frame.maxX + (isLast ? 0 : buttonSelectionPadding)
                        
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .offset(x: minX, y: frame.minY)
                            .frame(width: maxX - minX, height: frame.height)
                    }
                }
            }
            .modifier(TabBarStyleModifier())
            .padding(.horizontal, scrollViewContentPadding)
            .frame(minWidth: scrollViewWidth, alignment: .center)
        }
        .scrollClipDisabled()
        .scrollPosition($scrollPosition)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) {
            self.scrollViewWidth = $0
        }
        .padding(.bottom, scrollViewBottomMargin)
        .onChange(of: selection) {
            withAnimation(.spring(duration: 0.15)) {
                selectionIndicatorID = selection
            }
            
            withAnimation {
                scrollToSelection()
            }
        }
        .onFirstAppear {
            Task {
                // try await Task.sleep(for: .seconds(0.2))
                scrollToSelection()
            }
        }
    }
    
    private func tabButton(for tab: FloatingTab<ID>, isFirst: Bool, isLast: Bool) -> some View {
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
                .padding(.leading, isFirst ? buttonSelectionPadding : 0)
                .padding(.trailing, isLast ? buttonSelectionPadding : 0)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .named("buttonHStack"))}, action: { newValue in
                    buttonFrames[tab.id] = newValue
                })
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
    
    private func scrollToSelection() {
        scrollPosition.scrollTo(x: buttonFrames[selection]!.midX - scrollViewWidth / 2 + scrollViewContentPadding)
    }
    
    private var barHeight: CGFloat {
        // Rationale for bigger height on iPhone: to avoid the app switcher area while scrolling
        horizontalSizeClass == .regular ? 64 : 68
    }
    
    /// Space between scroll view and bottom edge.
    ///
    /// Larger for iPhone to account for app switcher bar and make the touch area slightly larger.
    private var scrollViewBottomMargin: CGFloat {
        horizontalSizeClass == .regular ? 24 : 21
    }
    
    /// Leading/trailing/bottom padding around the bar to add spacing to the device edges.
    private var scrollViewContentPadding: CGFloat {
        horizontalSizeClass == .regular ? 24 : 18
    }
    
    /// Horizontal spacing between buttons.
    private var buttonSpacing: CGFloat {
        horizontalSizeClass == .regular ? 6 : 3
    }
    
    /// Button internal horizontal padding.
    private var buttonInnerPadding: CGFloat {
        horizontalSizeClass == .regular ? 12 : 12
    }
    
    /// Horizontal padding added to the button to calculate selection size.
    private var buttonSelectionPadding: CGFloat {
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

private struct TabBarStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // $0.glassEffect(.regular, in: ConcentricRectangle(corners: .concentric(minimum: .fixed(15)), isUniform: true))
            content.glassEffect(.regular, in: .capsule)
            // $0.glassEffect(.regular, in: .rect(cornerRadius: 32))
        } else {
            let content = content.background(Color(UIColor.secondarySystemGroupedBackground), in: Capsule())
            
            if colorScheme == .dark {
                content.overlay {
                    Capsule().strokeBorder(Color(UIColor.separator), lineWidth: 0.5)
                }
            } else {
                content.shadow(color: .black.opacity(0.05), radius: 6)
            }
        }
    }
}
