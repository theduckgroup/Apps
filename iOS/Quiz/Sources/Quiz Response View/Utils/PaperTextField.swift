import Foundation
import SwiftUI

/// Text field with a line at the bottom similar to on paper.
struct PaperTextField: View {
    @Binding var text: String
    var multiline: Bool
    @FocusState private var focused: Bool
    @ScaledMetric private var verticalPadding = 3
    
    init(text: Binding<String>, multiline: Bool = false) {
        self._text = text
        self.multiline = multiline
    }
    
    var body: some View {
        TextField("", text: $text, axis: multiline ? .vertical : .horizontal)
//        TextField("", text: $text)
            .lineLimit(5)
            .focused($focused)
            .autocorrectionDisabled()
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(UIColor.systemGray3))
                    .frame(height: 1)
            }
            .onTapGesture {
                focused = true
            }
        
//        MultilineTextField(
//            text: $text,
//            textStyle: .body,
//            textColor: .secondaryLabel
//        )
//        .updatesBindingImmediately(false)
//        .focused($focused)
//        .padding(.top, verticalPadding)
//        .padding(.bottom, verticalPadding)
//        .autocorrectionDisabled()
//        .contentShape(Rectangle())
//        .overlay(alignment: .bottom) {
//            Rectangle()
//                .fill(Color(UIColor.systemGray3))
//                .frame(height: 1)
//        }
//        .onTapGesture {
//            focused = true
//        }
    }
}
