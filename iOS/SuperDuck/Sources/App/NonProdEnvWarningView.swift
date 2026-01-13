import Foundation
import SwiftUI

struct NonProdEnvWarningView: View  {
    var body: some View {
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

extension View {
    @ViewBuilder
    func nonProdEnvWarningOverlay() -> some View {
        safeAreaInset(edge: .bottom) {
            NonProdEnvWarningView()
                .padding(.bottom, 0)
        }
    }
}
