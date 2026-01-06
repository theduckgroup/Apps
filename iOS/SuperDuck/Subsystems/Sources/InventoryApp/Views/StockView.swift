import Foundation
import SwiftUI
import AppModule
import Backend
import Common
import CommonUI

struct StockView: View {
    @State var dataFetcher = ValueFetcher<(Store, Stock)>()
    @State var searchText = ""
    @State var isSearchPresented = false
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        bodyContent()
            .fetchOverlay(
                isFetching: dataFetcher.isFetching,
                fetchError: dataFetcher.error,
                retry: {
                    fetchData()
                }
            )
            .navigationTitle("Stock")
            .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .toolbar, prompt: nil)
            .onFirstAppear {
                fetchData()
            }
            .onReceive(api.eventHub.connectEvents) {
                fetchData()
            }
            .onReceive(api.eventHub.storeChangeEvents) {
                fetchData()
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView {
            if let (store, stock) = dataFetcher.value {
                LazyVStack(alignment: .leading, spacing: 0 /* pinnedViews: .sectionHeaders */) {
                    listView(store, stock)
                }
            }
        }
    }
    
    @ViewBuilder
    private func listView(_ store: Store, _ stock: Stock) -> some View {
        let listViewData = calculateListViewData(store, stock, searchText: searchText)
        
        ForEach(listViewData.sections) { section in
            Section {
                ForEach(section.items) { item in
                    itemRow(item)
                }
                
            } header: {
                sectionHeader(section, columnNames: section.id == listViewData.sections[0].id)
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(_ section: ListViewData.Section, columnNames: Bool) -> some View {
        // Both glass and blur background look terrible here
        
        VStack(alignment: .leading, spacing: 9) {
            Text(section.name)
                .font(.title2.leading(.tight))
                .bold()
                .padding(.horizontal)
                
            if columnNames {
                Group {
                    if horizontalSizeClass == .compact {
                        HStack {
                            Text("Name / Code")
                            Spacer()
                            Text("Quantity")
                        }
                        .padding(.bottom, 9)
                        
                    } else {
                        HStack {
                            Text("Name")
                                .containerRelativeFrame(.horizontal, count: 5, span: 3, spacing: 15, alignment: .leading)
                            Text("Code")
                                .containerRelativeFrame(.horizontal, count: 5, span: 1, spacing: 15, alignment: .leading)
                            Text("Quantity")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.bottom, 12)
                    }
                }
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing)
                .overlay(alignment: .bottom) { Divider() }
                .padding(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.bottom, columnNames ? 3 : 6)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func itemRow(_ item: ListViewData.Item) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(item.name)
                        Text(item.code).foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(item.quantity)").foregroundStyle(.secondary)
                }
                .padding(.vertical, 9)
                
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .containerRelativeFrame(.horizontal, count: 5, span: 3, spacing: 15, alignment: .leading)
                    Text(item.code)
                        .containerRelativeFrame(.horizontal, count: 5, span: 1, spacing: 15, alignment: .leading)
                    Text("\(item.quantity)")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 15)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading)
        }
    }
    
    private func fetchData() {
        dataFetcher.fetch {
            async let store = api.store()
            async let stock = api.stock()
            return try await (store, stock)
        }
    }
    
    private func calculateListViewData(_ store: Store, _ stock: Stock, searchText: String) -> ListViewData {
        let searchText = searchText.trimmingCharacters(in: .whitespaces)
        
        let sections: [ListViewData.Section] = store.catalog.sections
            .compactMap { storeSection in
                let storeItems = store.catalog.itemsForSection(storeSection)
                
                let listItems: [ListViewData.Item] = storeItems.compactMap { storeItem in
                    let visible: Bool = {
                        if searchText.isEmpty {
                            true
                        } else {
                            storeItem.name.localizedCaseInsensitiveContains(searchText) ||
                            storeItem.code.localizedCaseInsensitiveContains(searchText)
                        }
                    }()
                    
                    guard visible else {
                        return nil
                    }
                    
                    let quantity = stock.itemAttributes.first { $0.itemId == storeItem.id }?.quantity ?? 0
                    
                    return ListViewData.Item(
                        storeItem: storeItem,
                        name: highlight(storeItem.name, searchText),
                        code: highlight(storeItem.code, searchText),
                        quantity: quantity
                    )
                }
                
                let visible: Bool = {
                    if searchText == "" {
                        true
                    } else {
                        storeSection.name.localizedCaseInsensitiveContains(searchText) || listItems.count > 0
                    }
                }()
                
                guard visible else {
                    return nil
                }
                
                return ListViewData.Section(
                    storeSection: storeSection,
                    name: highlight(storeSection.name, searchText),
                    items: listItems
                )
                
            }
        
        return ListViewData(sections: sections)
    }
    
    private func highlight(_ string: String, _ substring: String) -> AttributedString {
        var attrString = AttributedString(string)
        
        if let range = attrString.range(of: substring, options: .caseInsensitive) {
            attrString[range].foregroundColor = UIColor.label
            attrString[range].backgroundColor = UIColor.systemYellow
        }
        
        return attrString
    }
}

private extension StockView {
    struct ListViewData {
        var sections: [Section]
        
        struct Section: Identifiable {
            var storeSection: Store.Section
            var name: AttributedString
            var items: [Item]
            
            var id: String {
                storeSection.id
            }
        }
        
        struct Item: Identifiable {
            var storeItem: Store.Item
            var name: AttributedString
            var code: AttributedString
            var quantity: Int
            
            var id: String {
                storeItem.id
            }
        }
    }
}

#Preview {
    TabView() {
        Tab("Inventory", image: "document.fill") {
            NavigationStack {
                StockView()
            }
        }
        
        Tab("FOH Test", image: "document.fill") {
            EmptyView()
        }
    }
    .previewEnvironment()
}
