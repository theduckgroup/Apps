import Foundation
import SwiftUI

public extension View {
    func modified<R: View>(@ViewBuilder _ with: (Self) -> R) -> R {
        with(self)
    }
}
