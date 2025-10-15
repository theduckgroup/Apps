import Foundation
import SwiftUI
import Equatable

struct ItemsView: View {
    @Environment(QuizViewModel.self) private var viewModel
    @ScaledMetric private var itemSpacing = 24
    
    var body: some View {
        VStack(alignment: .leading, spacing: itemSpacing) {
            ForEach(viewModel.quiz.sections, id: \.id) { section in
                ForEach(Array(section.rows.enumerated()), id: \.offset) { rowIndex, row in
                    let itemResponse = viewModel.itemResponseForItemID(row.itemId)
                    let itemResponseBinding = viewModel.itemResponseBindingForID(itemResponse.id)
                    itemResponseRow(itemResponseBinding, rowIndex: rowIndex)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func itemResponseRow(_ itemResponse: Binding<QuizResponse.ItemResponse>, rowIndex: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            ZStack(alignment: .leading) {
                Text("\(rowIndex + 1).")
                    .fontWeight(.bold)
                
                Text("00")
                    .opacity(0)
            }
            
            let item = viewModel.quiz.itemForID(itemResponse.wrappedValue.itemId)!
            ItemResponseView(item: item, itemResponse: itemResponse)
        }
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

// @Equatable
private struct SelectedResponseItemResponseView: View {
    var item: Quiz.SelectedResponseItem
    @Binding var response: QuizResponse.SelectedResponseItemResponse
    var compact: Bool
    @ScaledMetric private var promptOptionSpacing = 12
    @ScaledMetric private var optionSpacing = 3
    @ScaledMetric private var optionVerticalPadding = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: promptOptionSpacing) {
            Text(item.data.prompt)
                // .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: optionSpacing) {
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
                                // .foregroundStyle(selected ? .tint : .primary)
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.top, option.id != item.data.options.first?.id ? optionVerticalPadding : 0)
                        .padding(.bottom, option.id != item.data.options.last?.id ? optionVerticalPadding : 0)
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
    @ScaledMetric private var stackSpacing = 6
    @ScaledMetric private var compactStackSpacing = 2
    @FocusState private var focused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            // TODO: Check
            let isRegularSizeClass = horizontalSizeClass == .regular
            
            switch (isRegularSizeClass, item.data.layout) {
            case (true, .inline):
                HStack(alignment: .firstTextBaseline, spacing: 15) {
                    Text(item.data.prompt)
                         .layoutPriority(1)
                        
                    PaperTextField(text: $response.data.value, multiline: false)
                        .focused($focused)
                        .foregroundStyle(.blue)
                        .frame(minWidth: 100)
                }
                
            case (_, .stack), (false, .inline):
                VStack(alignment: .leading, spacing: compact ? compactStackSpacing : stackSpacing) {
                    Text(item.data.prompt)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    PaperTextField(text: $response.data.value, multiline: true)
                        .focused($focused)
                        .foregroundStyle(.blue)
                }
            }
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
    @ScaledMetric var promptItemSpacing = 15
    @ScaledMetric var itemSpacing = 21
    @ScaledMetric var bulletSize = 9
    @ScaledMetric var bulletWidth = 21
    @ScaledMetric var bulletOffset = -2

    var body: some View {
        VStack(alignment: .leading, spacing: promptItemSpacing) {
            Text(item.data.prompt)
                // .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: itemSpacing) {
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
