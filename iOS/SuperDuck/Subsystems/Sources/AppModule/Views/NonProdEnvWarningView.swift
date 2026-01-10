import Foundation
public import SwiftUI

public struct NonProdEnvWarningView: View  {
    public init() {}
    
    public var body: some View {
        if AppInfo.buildTarget != .prod && AppInfo.buildTarget != .prodAdhoc {
            Text("Test Build / \(AppInfo.marketingVersion)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

public extension View {
    @ViewBuilder
    func nonProdEnvWarningOverlay() -> some View {
        safeAreaInset(edge: .bottom) {
            NonProdEnvWarningView()
                .padding(.bottom, 9)
        }
    }
}
