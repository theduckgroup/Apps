import Foundation
import SwiftUI

struct PageNavButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
            
        } label: {
            HStack(spacing: 6) {
                Text(title)
                
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
        }
        .buttonStyle(.bordered)
    }
}
