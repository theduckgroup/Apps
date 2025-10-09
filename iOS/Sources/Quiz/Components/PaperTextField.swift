import Foundation
import SwiftUI

/// Text field with a line at the bottom similar to on paper. The line disappears once text has been entered.
struct PaperTextField: View {
    var title: String
    @Binding var text: String
    
    init(_ title: String = "", text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
            TextField(title, text: $text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    text.isEmpty ? Divider() : nil
                }
    }
}
