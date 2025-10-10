import Foundation
import SwiftUI

/// Text field with a line at the bottom similar to on paper.
struct PaperTextField: View {
    @Binding var text: String
    @FocusState var focused: Bool
    @ScaledMetric var verticalPadding = 3
    
    init(text: Binding<String>) {
        self._text = text
    }
    
    var body: some View {
//        TextField("", text: $text, axis: .vertical)
//            .foregroundStyle(.secondary)
//            .lineLimit(5)
//            .focused($focused)
//            .padding(.top, verticalPadding)
//            .padding(.bottom, verticalPadding)
//            .autocorrectionDisabled()
//            .contentShape(Rectangle())
//            .overlay(alignment: .bottom) {
//                Rectangle()
//                    .fill(Color(UIColor.systemGray3))
//                    .frame(height: 1)
//            }
//            .onTapGesture {
//                focused = true
//            }
        
        MultilineTextField(
            text: $text,
            font: .preferredFont(forTextStyle: .body),
            textColor: .secondaryLabel
        )
        .focused($focused)
        .padding(.top, verticalPadding)
        .padding(.bottom, verticalPadding)
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
    }
}
