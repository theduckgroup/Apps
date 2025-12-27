import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func nonProdWarningOverlay() -> some View {
        overlay(alignment: .bottomLeading) {
            if AppInfo.buildTarget != .prod {
                Text("Test Build / \(AppInfo.marketingVersion)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow, in: RoundedRectangle(cornerRadius: 6))
                    .padding(.vertical, 9)
                    .padding(.leading)
            }
        }
    }
}
