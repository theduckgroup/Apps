import Foundation
import SwiftUI

struct SearchField: View {
    var placeholder = ""
    @Binding var text: String
    @FocusState var focused: Bool
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .focused($focused)
                
            
            if !text.isEmpty {
                Button {
                    text = ""
                    
                } label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.tertiarySystemFill))
        }
        .onTapGesture {
            focused = true
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    
    NavigationStack {
        ScrollView {
            SearchField("Search", text: $text)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("List")
    }
    .preferredColorScheme(.dark)
}
