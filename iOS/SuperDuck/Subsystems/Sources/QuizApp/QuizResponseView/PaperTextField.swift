import Foundation
import SwiftUI
import CommonUI

/// Text field with a line at the bottom similar to on paper.
struct PaperTextField: View {
    @Binding var text: String
    var bindingUpdateMode: TextFieldBindingUpdateMode
    var multiline: Bool
    var textStyle: UIFont.TextStyle
    var textColor: Color
    @FocusState private var focused: Bool
    @ScaledMetric private var verticalPadding = 3
    
    init(
        text: Binding<String>,
        bindingUpdateMode: TextFieldBindingUpdateMode = .onEndEditing,
        multiline: Bool = false,
        textStyle: UIFont.TextStyle = .body,
        textColor: Color = .secondary
    ) {
        self._text = text
        self.bindingUpdateMode = bindingUpdateMode
        self.multiline = multiline
        self.textStyle = textStyle
        self.textColor = textColor
    }
    
    var body: some View {
        Group {
            if multiline {
                MultilineTextField(
                    text: $text,
                    bindingUpdateMode: bindingUpdateMode,
                    textStyle: textStyle,
                    textColor: textColor
                )
                
            } else {
                SingleLineTextField(
                    "",
                    text: $text,
                    textStyle: textStyle,
                    textColor: textColor
                )
            }
        }
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
        
        // TextField implementation has severe performance issue
        /*
        TextField("", text: $text, axis: multiline ? .vertical : .horizontal)
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
        */
    }
}
