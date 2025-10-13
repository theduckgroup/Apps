import Foundation
import SwiftUI
import Equatable

struct QuizPageView: View {
    var page: QuizViewModel.QuizResponsePage
    var nextVisible: Bool
    var onNext: () -> Void
    var submitVisible: Bool
    var onSubmit: () -> Void
    @Environment(QuizViewModel.self) private var quizViewModel
    @ScaledMetric private var spacing = 15
    
    var body: some View {
        @Bindable var quizViewModel = quizViewModel
        
//        ScrollViewReader { reader in
//            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 0).id("top")
                    
                    VStack(spacing: spacing) {
                        ForEach(Array(page.rows.enumerated()), id: \.offset) { rowIndex, row in
                            Group {
                                switch row {
                                case .itemResponse(let id, let indexInSection):
                                    let itemResponse = quizViewModel.itemResponseBindingForID(id)
                                    itemResponseRow(itemResponse, index: indexInSection)
                                }
                            }
                            .id(rowIndex)
                        }
                        
                        // bottomButtons()
                    }
                    .padding()
                }
//            }
//            .scrollDismissesKeyboard(.automatic)
//            .onAppear {
//                reader.scrollTo("top")
//            }
//        }
    }
    
    @ViewBuilder
    private func itemResponseRow(_ itemResponse: Binding<QuizResponse.ItemResponse>, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            ZStack(alignment: .leading) {
                Text("\(index + 1).")
                    .fontWeight(.bold)
                
                Text("00")
                    .opacity(0)
            }
            
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId)!
            ItemResponseView(item: item, itemResponse: itemResponse)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func bottomButtons() -> some View {
        HStack {
            Spacer()
            
            if nextVisible {
                PageNavButton("Next", systemImage: "chevron.right") {
                    onNext()
                }
            }

            if submitVisible {
                PageNavButton("Submit") {
                    onSubmit()
                }
                .bold()
            }
        }
        .padding(.top, 21)
    }
}

// Equatable DOES make a significant difference
// Check this by typing random letters quickly

struct ItemResponseView: View, Equatable {
    var item: Quiz.Item
    @Binding var itemResponse: QuizResponse.ItemResponse
    var compact: Bool = false
    
    static func == (x: ItemResponseView, y: ItemResponseView) -> Bool {
        areEqual(x.item, y.item) &&
        areEqual(x.itemResponse, y.itemResponse) &&
        x.compact == y.compact
    }
    
    var body: some View {
        switch itemResponse {
        case is QuizResponse.SelectedResponseItemResponse:
            let castItem = item as! Quiz.SelectedResponseItem
            
            let castItemResponse = Binding {
                itemResponse as! QuizResponse.SelectedResponseItemResponse
            } set: {
                itemResponse = $0
            }
                        
            SelectedResponseItemResponseView(item: castItem, response: castItemResponse, compact: compact)
            
        case is QuizResponse.TextInputItemResponse:
            let castItem = item as! Quiz.TextInputItem
            
            let castItemResponse = Binding {
                itemResponse as! QuizResponse.TextInputItemResponse
            } set: {
                itemResponse = $0
            }

            TextInputItemResponseView(item: castItem, response: castItemResponse, compact: compact)
            
        case is QuizResponse.ListItemResponse:
            let castItem = item as! Quiz.ListItem
            
            let castItemResponse = Binding {
                itemResponse as! QuizResponse.ListItemResponse
            } set: {
                itemResponse = $0
            }
                        
            ListItemResponseView(item: castItem, response: castItemResponse)
            
        default:
            preconditionFailure()
        }
    }

}

@Equatable
private struct SelectedResponseItemResponseView: View {
    var item: Quiz.SelectedResponseItem
    @Binding var response: QuizResponse.SelectedResponseItemResponse
    var compact: Bool
    @ScaledMetric private var promptSpacing = 6
    @ScaledMetric private var itemSpacing = 3
    @ScaledMetric private var itemVerticalPadding = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: promptSpacing) {
            Text(item.data.prompt)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: itemSpacing) {
                ForEach(item.data.options) { option in
                    Button {
                        UIApplication.dismissKeyboard()
                        
                        if let index = response.data.selectedOptions.map(\.id).firstIndex(of: option.id) {
                            response.data.selectedOptions.remove(at: index)
                        } else {
                            response.data.selectedOptions.append(.init(id: option.id, value: option.value))
                        }
                        
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            let selected = response.data.selectedOptions.map(\.id).contains(option.id)
                            
                            Image(systemName: selected ? "checkmark.square.fill" : "square")
                                .modified {
                                    if selected {
                                        $0.foregroundStyle(.blue)
                                    } else {
                                        $0.foregroundStyle(.secondary)
                                    }
                                }
                                // .foregroundStyle(selected ? .tint : .secondary)
                            
                            Text(option.value)
                                .multilineTextAlignment(.leading)
//                                .modified {
//                                    if selected {
//                                        $0.foregroundStyle(.blue)
//                                    } else {
//                                        $0.foregroundStyle(.primary)
//                                    }
//                                }
                                // .foregroundStyle(selected ? .tint : .primary)
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, itemVerticalPadding)
                        .contentShape(Rectangle())
                        .transaction { $0.animation = nil }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

@Equatable
private struct TextInputItemResponseView: View {
    var item: Quiz.TextInputItem
    @Binding var response: QuizResponse.TextInputItemResponse
    var compact: Bool
    @ScaledMetric private var spacing = 6
    @ScaledMetric private var compactSpacing = 2
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? compactSpacing : spacing) {
            Text(item.data.prompt)
                .fixedSize(horizontal: false, vertical: true)
            
            PaperTextField(text: $response.data.value, multiline: true)
                .focused($focused)
                .foregroundStyle(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}

@Equatable
private struct ListItemResponseView: View {
    var item: Quiz.ListItem
    @Binding var response: QuizResponse.ListItemResponse
    @ScaledMetric var bulletSize = 9
    @ScaledMetric var bulletWidth = 21
    @ScaledMetric var bulletOffset = -2
    @ScaledMetric var spacing = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(item.data.prompt)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: spacing) {
                ForEach($response.data.itemResponses, id: \.id) { $subitemResponse in
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("■")
                            .font(.system(size: bulletSize))
                            .frame(width: bulletWidth, alignment: .leading)
                            .offset(y: bulletOffset)
                        
                        let subitem = item.data.items.first { $0.id == subitemResponse.itemId }!
                        ItemResponseView(item: subitem, itemResponse: $subitemResponse, compact: true)
                    }
                }
            }
        }
    }
}
