import Foundation
import SwiftUI

struct QuizPageView: View {
    @Environment(QuizViewModel.self) private var quizViewModel
    var page: QuizViewModel.Page
    
    init(page: QuizViewModel.Page) {
        self.page = page
    }
    
    var body: some View {
        @Bindable var quizViewModel = quizViewModel
        
        ScrollView(.vertical) {
            ForEach(Array(page.rows.enumerated()), id: \.offset) { index, row in
                switch row {
                case .itemResponse(let id):
                    // let itemResponse = quizViewModel.quizResponse.itemResponses.first { $0.id == id }
                    let index = quizViewModel.quizResponse.itemResponses.firstIndex { $0.id == id }!
                    let itemResponse = $quizViewModel.quizResponse.itemResponses[index]
                    viewForItemResponse(itemResponse)
                }
            }
        }
    }
    
    @ViewBuilder
    private func viewForItemResponse(_ itemResponse: Binding<QuizResponse.ItemResponse>) -> some View {
        switch itemResponse.wrappedValue {
        case .selectedResponseItemResponse(_):
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId)!.as(Quiz.SelectedResponseItem.self)
            
            let itemResponse = Binding {
                itemResponse.wrappedValue.as(QuizResponse.SelectedResponseItemResponse.self)
            } set: {
                itemResponse.wrappedValue = .selectedResponseItemResponse($0)
            }
                        
            SelectedResponseItemResponseView(item: item, response: itemResponse)
            
        case .textInputItemResponse(_):
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId)!.as(Quiz.TextInputItem.self)
            
            let itemResponse = Binding {
                itemResponse.wrappedValue.as(QuizResponse.TextInputItemResponse.self)
            } set: {
                itemResponse.wrappedValue = .textInputItemResponse($0)
            }
                        
            TextInputItemResponseView(item: item, response: itemResponse)
            
        case .listItemResponse(_):
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId)!.as(Quiz.ListItem.self)
            
            let itemResponse = Binding {
                itemResponse.wrappedValue.as(QuizResponse.ListItemResponse.self)
            } set: {
                itemResponse.wrappedValue = .listItemResponse($0)
            }
                        
            ListItemResponseView(item: item, response: itemResponse)
        }
    }
}


private struct SelectedResponseItemResponseView: View {
    var item: Quiz.SelectedResponseItem
    @Binding var response: QuizResponse.SelectedResponseItemResponse
    
    var body: some View {
        VStack {
            Text(item.data.prompt)
            
            VStack {
                ForEach(item.data.options) { option in
                    Button {
                        if let index = response.data.selectedOptions.map(\.id).firstIndex(of: option.id) {
                            response.data.selectedOptions.remove(at: index)
                        } else {
                            response.data.selectedOptions.append(.init(id: option.id))
                        }
                        
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            let selected = response.data.selectedOptions.map(\.id).contains(option.id)
                            Image(systemName: selected ? "checkmark.square" : "square")
                            Text(option.value)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct TextInputItemResponseView: View {
    var item: Quiz.TextInputItem
    @Binding var response: QuizResponse.TextInputItemResponse
    
    var body: some View {
        VStack {
            Text(item.data.prompt)
            PaperTextField("", text: $response.data.value)
        }
    }
}

private struct ListItemResponseView: View {
    var item: Quiz.ListItem
    @Binding var response: QuizResponse.ListItemResponse
    
    var body: some View {
        VStack {
            Text(item.data.prompt)
            Text("TODO")
        }
    }
}
