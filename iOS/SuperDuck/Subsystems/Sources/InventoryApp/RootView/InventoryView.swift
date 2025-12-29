import Foundation
import SwiftUI
import AppModule
import Backend
import Common

struct InventoryView: View {
    @State var store: Vendor?
    @State var isFetching = false
    @State var fetchError: Error?
    @State private var showsFilter = false
    @State private var filterText = ""
    @FocusState private var filterFocused: Bool
    
    @Environment(Auth.self) var auth
    @Environment(API.self) var api
    // @Environment(AppDefaults.self) var appDefaults
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            bodyContent()
                .navigationTitle("Inventory")
                .navigationBarTitleDisplayMode(.inline)
            // .toolbarVisibility(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        searchButton()
                    }
                }
        }
        .onFirstAppear {
            fetch()
        }
        .onSceneBecomeActive {
            fetch()
        }
        .onReceive(api.eventHub.connectEvents) {
            fetch()
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        VStack(alignment: .center, spacing: 0) {
            searchField()
            contentView()
        }
        .fetchOverlay(
            isFetching: isFetching,
            fetchError: fetchError,
            retry: {
                fetch()
            }
        )
    }
    
    @ViewBuilder
    private func searchButton() -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                if !showsFilter {
                    showsFilter = true
                    filterFocused = true
                    
                } else {
                    showsFilter = false
                }
            }
            
        } label: {
            Image(systemName: "magnifyingglass")
        }
    }
    
    @ViewBuilder
    private func searchField() -> some View {
        if showsFilter {
            TextField("Filter", text: $filterText)
                .focused($filterFocused)
                .padding(.horizontal, 9)
                .padding(.vertical, 9)
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        ScrollView {
            if let store {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    listView(store)
                }
            }
        }
    }
    
    @ViewBuilder
    private func listView(_ vendor: Vendor) -> some View {
        let listData = listData(
            vendor: vendor, filterEnabled: showsFilter, filterText: filterText
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
        Text(section.name)
            .font(.title2.leading(.tight))
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemBackground))
            .overlay(alignment: .bottom) {
                Divider()
            }
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
    
    private func fetch() {
        Task {
            do {
                isFetching = true
                fetchError = nil

                let fetchedStore = try await api.store()
                
                store = fetchedStore
                isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }

                // Keep existing store
                isFetching = false
                fetchError = error
            }
        }
    }
    
    private func listData(vendor: Vendor, filterEnabled: Bool, filterText: String) -> ListData {
        let filterText = filterText.trimmingCharacters(in: .whitespaces)
        
        if !filterEnabled {
            return ListData(
                sections: vendor.sections.map { vendorSection in
                    ListData.Section(
                        vendorSection: vendorSection,
                        name: AttributedString(vendorSection.name),
                        items: vendor.itemsForSection(vendorSection).map { vendorItem in
                            ListData.Item(
                                vendorItem: vendorItem,
                                name: AttributedString(vendorItem.name),
                                // name: highlight(vendorItem.name, "Yoghurt"),
                                code: AttributedString(vendorItem.code),
                                quantity: vendorItem.quantity
                            )
                        }
                    )
                }
            )
            
        } else {
            let sections: [ListData.Section] = vendor.sections
                .compactMap { vendorSection in
                    let vendorItems = vendor.itemsForSection(vendorSection)
                    
                    let listItems: [ListData.Item] = vendorItems.compactMap { vendorItem in
                        guard filterText == "" ||
                                vendorItem.name.localizedCaseInsensitiveContains(filterText) else {
                            return nil
                        }
                        
                        return ListData.Item(
                            vendorItem: vendorItem,
                            name: highlight(vendorItem.name, filterText),
                            code: highlight(vendorItem.code, filterText),
                            quantity: vendorItem.quantity
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
            attrString[range].foregroundColor = .systemYellow
            // attrString[range].backgroundColor = .systemYellow
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
    
    enum FetchState {
        case idle
        case fetching
        case error(Error)
    }
}

#Preview {
    NavigationStack {
        InventoryView()
            .preferredColorScheme(.dark)
            .navigationTitle(Text("Inventory"))
    }
}
