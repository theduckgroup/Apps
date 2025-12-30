import Foundation
import SwiftUI
import AppModule
import Backend
import Common

struct InventoryView: View {
    @State var dataFetcher = Fetcher<(Vendor, StoreStock)>()
    @State private var showsFilter = false
    @State private var filterText = ""
    @FocusState private var filterFocused: Bool
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
            .onSceneBecomeActive {
                fetchData()
            }
            .onReceive(api.eventHub.connectEvents) {
                fetchData()
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ScrollView {
            if let (store, stock) = dataFetcher.value {
                // , pinnedViews: .sectionHeaders
                LazyVStack(alignment: .leading, spacing: 0) {
                    listView(store, stock)
                }
            }
        }
        .modified {
            if #available(iOS 26, *) {
                $0.scrollEdgeEffectStyle(.hard, for: .top)
            } else {
                $0
            }
        }
    }
//    
//    @ViewBuilder
//    private func searchButton() -> some View {
//        Button {
//            withAnimation(.spring(duration: 0.2)) {
//                if !showsFilter {
//                    showsFilter = true
//                    filterFocused = true
//                    
//                } else {
//                    showsFilter = false
//                }
//            }
//            
//        } label: {
//            Image(systemName: "magnifyingglass")
//        }
//    }
//    
//    @ViewBuilder
//    private func searchField() -> some View {
//        if showsFilter {
//            TextField("Filter", text: $filterText)
//                .focused($filterFocused)
//                .padding(.horizontal, 9)
//                .padding(.vertical, 9)
//        }
//    }
    
    @ViewBuilder
    private func listView(_ vendor: Vendor, _ stock: StoreStock) -> some View {
        let listData = listData(
            vendor: vendor, stock: stock, filterEnabled: showsFilter, filterText: filterText
        )
        
        ForEach(listData.sections) { section in
            Section {
                ForEach(section.items) { item in
                    itemRow(item)
                }
                
            } header: {
                sectionHeader(section)
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(_ section: ListData.Section) -> some View {
        // Both glass and blur background look terrible here
        
        Text(section.name)
            .font(.title2.leading(.tight))
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func itemRow(_ item: ListData.Item) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.code)
            }
            
            Spacer()
            
            Text("\(item.quantity)")
        }
        .padding(.horizontal)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading)
        }
    }
    
    private func fetchData() {
        dataFetcher.fetch {
            async let store = api.store()
            async let stock = api.storeStock()
            return try await (store, stock)
        }
    }
    
    private func listData(vendor: Vendor, stock: StoreStock, filterEnabled: Bool, filterText: String) -> ListData {
        let filterText = filterText.trimmingCharacters(in: .whitespaces)
        
        if !filterEnabled {
            return ListData(
                sections: vendor.catalog.sections.map { vendorSection in
                    ListData.Section(
                        vendorSection: vendorSection,
                        name: AttributedString(vendorSection.name),
                        items: vendor.catalog.itemsForSection(vendorSection).map { vendorItem in
                            let quantity = stock.itemAttributes.first { $0.itemId == vendorItem.id }?.quantity ?? 0
                            
                            return ListData.Item(
                                vendorItem: vendorItem,
                                name: AttributedString(vendorItem.name),
                                // name: highlight(vendorItem.name, "Yoghurt"),
                                code: AttributedString(vendorItem.code),
                                quantity: quantity
                            )
                        }
                    )
                }
            )
            
        } else {
            let sections: [ListData.Section] = vendor.catalog.sections
                .compactMap { vendorSection in
                    let vendorItems = vendor.catalog.itemsForSection(vendorSection)
                    
                    let listItems: [ListData.Item] = vendorItems.compactMap { vendorItem in
                        guard filterText == "" ||
                                vendorItem.name.localizedCaseInsensitiveContains(filterText) else {
                            return nil
                        }
                        
                        let quantity = stock.itemAttributes.first { $0.itemId == vendorItem.id }?.quantity ?? 0
                        
                        return ListData.Item(
                            vendorItem: vendorItem,
                            name: highlight(vendorItem.name, filterText),
                            code: highlight(vendorItem.code, filterText),
                            quantity: quantity
                        )
                    }
                    
                    guard filterText == "" ||
                            vendorSection.name.localizedCaseInsensitiveContains(filterText) ||
                            listItems.count > 0 else {
                        return nil
                    }
                    
                    return ListData.Section(
                        vendorSection: vendorSection,
                        name: highlight(vendorSection.name, filterText),
                        items: listItems
                    )
                    
                }
            
            return ListData(sections: sections)
        }
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

private extension InventoryView {
    struct ListData {
        var sections: [Section]
        
        struct Section: Identifiable {
            var vendorSection: Vendor.Section
            var name: AttributedString
            var items: [Item]
            
            var id: String {
                vendorSection.id
            }
        }
        
        struct Item: Identifiable {
            var vendorItem: Vendor.Item
            var name: AttributedString
            var code: AttributedString
            var quantity: Int
            
            var id: String {
                vendorItem.id
            }
        }
    }
}

#Preview {
    TabView() {
        Tab("Inventory", image: "document.fill") {
            NavigationStack {
                InventoryView()
            }
        }
        
        Tab("FOH Test", image: "document.fill") {
            EmptyView()
        }
    }
    .previewEnvironment()
}
