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
            VStack {
                ForEach(Array(page.rows.enumerated()), id: \.offset) { index, row in
                    switch row {
                    case .itemResponse(let id):
                        let index = quizViewModel.quizResponse.itemResponses.firstIndex { $0.id == id }!
                        let itemResponse = $quizViewModel.quizResponse.itemResponses[index]
                        viewForItemResponse(itemResponse)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func viewForItemResponse(_ itemResponse: Binding<QuizResponse.ItemResponse>) -> some View {
        switch itemResponse.wrappedValue {
        case is QuizResponse.SelectedResponseItemResponse:
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId) as! Quiz.SelectedResponseItem
            
            let itemResponse = Binding {
                itemResponse.wrappedValue as! QuizResponse.SelectedResponseItemResponse
            } set: {
                itemResponse.wrappedValue = $0
            }
                        
            SelectedResponseItemResponseView(item: item, response: itemResponse)
            
        case is QuizResponse.TextInputItemResponse:
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId) as! Quiz.TextInputItem
            
            let itemResponse = Binding {
                itemResponse.wrappedValue as! QuizResponse.TextInputItemResponse
            } set: {
                itemResponse.wrappedValue = $0
            }

            TextInputItemResponseView(item: item, response: itemResponse)
            
        case is QuizResponse.ListItemResponse:
            let item = quizViewModel.quiz.itemForID(itemResponse.wrappedValue.itemId) as! Quiz.ListItem
            
            let itemResponse = Binding {
                itemResponse.wrappedValue as! QuizResponse.ListItemResponse
            } set: {
                itemResponse.wrappedValue = $0
            }
                        
            ListItemResponseView(item: item, response: itemResponse)
            
        default:
            preconditionFailure()
        }
    }
}


private struct SelectedResponseItemResponseView: View {
    var item: Quiz.SelectedResponseItem
    @Binding var response: QuizResponse.SelectedResponseItemResponse
    
    var body: some View {
        VStack {
            Text(item.data.prompt)
            
            VStack(alignment: .leading) {
                ForEach(item.data.options) { option in
                    Button {
                        if let index = response.data.selectedOptions.map(\.id).firstIndex(of: option.id) {
                            response.data.selectedOptions.remove(at: index)
                        } else {
                            response.data.selectedOptions.append(.init(id: option.id, value: option.value))
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
        VStack(alignment: .leading) {
            Text(item.data.prompt)
            PaperTextField("", text: $response.data.value)
        }
    }
}

private struct ListItemResponseView: View {
    var item: Quiz.ListItem
    @Binding var response: QuizResponse.ListItemResponse
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.data.prompt)
            Text("TODO")
        }
    }
}
