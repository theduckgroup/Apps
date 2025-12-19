import Foundation
import SwiftUI
import Backend
import Common
import CommonUI
import SwiftBSON

struct NewReportView: View {
    var template: WSTemplate
    var user: WSReport.User
    @State private var suppliersDataMap: [String: SupplierData]
    @State private var customSuppliersData: [CustomSupplierData] = []
    @State private var scrollPosition: String?
    @State private var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    
    init(template: WSTemplate, user: WSReport.User) {
        self.template = template
        self.user = user

        self.suppliersDataMap = Dictionary(
            uniqueKeysWithValues: template.suppliers.map {
                ($0.id, SupplierData(supplier: $0))
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content()
            }
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .safeAreaPadding(.bottom, 54) // For padding above keyboard
            .background(Color(.secondarySystemBackground))
            .navigationTitle("New Spending")
            .toolbar { toolbarContent() }
            .presentations(ps)
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Submit") {
                handleSubmit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasNonZeroAmount())
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        VStack(alignment: .leading, spacing: 21) {
            ForEach(template.sections, id: \.id) { section in
                sectionView(section)
            }
            
            customSuppliersSectionView()
        }
        .padding()
    }
    
    @ViewBuilder
    private func sectionView(_ section: WSTemplate.Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.name)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(section.rows, id: \.supplierId) { row in
                    let supplier = template.suppliers.first { $0.id == row.supplierId }
                    
                    if let supplier {
                        let supplierData = suppliersDataMap[supplier.id]!
                        SupplierView(supplier: supplier, data: supplierData)
                            .id(supplier.id)
                        
                        if row.supplierId != section.rows.last?.supplierId {
                            Divider()
                        }
                        
                    } else {
                        Text("ERROR").foregroundStyle(.red)
                    }
                }
            }
            .sectionBackground()
        }
    }
    
    @ViewBuilder
    private func customSuppliersSectionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Other Suppliers")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if customSuppliersData.count > 0 {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(customSuppliersData, id: \.id) { supplierData in
                        CustomSupplierView(
                            data: supplierData,
                            onDelete: {
                                withAnimation(.spring) {
                                    customSuppliersData.removeAll { $0.id == supplierData.id }
                                }
                            }
                        )
                        .id(supplierData.id)
                        
                        if supplierData.id != customSuppliersData.last?.id {
                            Divider()
                        }
                    }
                }
                .sectionBackground()
            }
            
            Button {
                handleAddCustomSupplier()
                
            } label: {
                Label("Add Supplier", systemImage: "plus")
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .id("addButton")
        }
    }
    
    private func handleAddCustomSupplier() {
        let c = CustomSupplierData()
        
        withAnimation(.spring) {
            customSuppliersData.append(c)
        }
        
        // Don't need to scroll because we focus supplier name shortly
        
//        Task {
//            try! await Task.sleep(for: .seconds(1))
//            
//            withAnimation {
//                scrollPosition = "addButton"
//            }
//        }
    }
        
    private func handleSubmit() {
        UIApplication.dismissKeyboard()
        
        do {
            try validate()
            
        } catch {
            ps.presentAlert(error: error)
            return
        }
        
        ps.presentAlert(title: "Submit Spending?", message: "") {
            Button("Submit") {
                Task {
                    do {
                        try await submit()
                        dismiss()
                        
                    } catch {
                        ps.presentAlert(error: error)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func submit() async throws {
        ps.presentProgressHUD(title: "Submitting...")
        
        defer {
            ps.dismiss()
        }
        
        try! await Task.sleep(for: .seconds(0.5))
        
        let report = report()
        try await API.shared.post(method: "POST", path: "/submit", body: report)
    }
    
    private func validate() throws {
        guard hasNonZeroAmount() else {
            throw GenericError("Must enter amount for at least one supplier")
        }
    }
    
    private func hasNonZeroAmount() -> Bool {
        let amounts = suppliersDataMap.values.map(\.amount) + customSuppliersData.map(\.amount)
        return amounts.contains { $0 > 0 }
    }
    
    /// Creates report from view data.
    private func report() -> WSReport {
        WSReport(
            template: template,
            user: user,
            date: Date(),
            suppliersData: template.suppliers.map {
                let data = suppliersDataMap[$0.id]!
                return WSReport.SupplierData(supplierId: $0.id, amount: data.amount, gst: data.gst)
            },
            customSuppliersData: customSuppliersData.map {
                WSReport.CustomSupplierData(name: $0.name, amount: $0.amount, gst: $0.gst)
            }
        )
    }
}

private struct SupplierView: View {
    var supplier: WSTemplate.Supplier
    @Bindable var data: SupplierData
    @FocusState var amountFocused: Bool
    @FocusState var gstFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            regularBody()
        } else {
            compactBody()
        }
    }
    
    @ViewBuilder
    private func regularBody() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 36) {
            Text(supplier.name)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .firstTextBaseline) {
                AmountField(value: $data.amount)
                GSTField(gstMethod: supplier.gstMethod, value: $data.gst)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    @ViewBuilder
    private func compactBody() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(supplier.name)
                .fontWeight(.bold)
            
            HStack(alignment: .firstTextBaseline) {
                AmountField(value: $data.amount)
                GSTField(gstMethod: supplier.gstMethod, value: $data.gst)
            }
        }
        .padding()
    }
}

private struct CustomSupplierView: View {
    @Bindable var data: CustomSupplierData
    var onDelete: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var nameFocused: Bool
    @State private var presentsDeleteConfirmation = false
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularBody()
            } else {
                compactBody()
            }
        }
        .onFirstAppear {
            Task {
                try await Task.sleep(for: .seconds(0.1))
                nameFocused = true
            }
        }
        .alert("Confirm", isPresented: $presentsDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete this supplier?")
        }
    }
    
    @ViewBuilder
    private func regularBody() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 36) {
            nameField()
            
            HStack(alignment: .firstTextBaseline) {
                AmountField(value: $data.amount)
                GSTField(gstMethod: .input, value: $data.gst)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) {
                deleteButton()
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func compactBody() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            nameField()
                
            HStack(alignment: .firstTextBaseline) {
                AmountField(value: $data.amount)
                GSTField(gstMethod: .input, value: $data.gst)
            }
        }
        .overlay(alignment: .topTrailing) {
            deleteButton()
        }
        .padding()
    }
    
    @ViewBuilder
    private func nameField() -> some View {
        TextField("Supplier Name", text: $data.name)
            .focused($nameFocused)
            .foregroundStyle(.tint)
            .fontWeight(.bold)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func deleteButton() -> some View {
        Button {
            if data.name == "" && data.amount == 0 && data.gst == 0 {
                onDelete()
            } else {
                presentsDeleteConfirmation = true
            }
            
        } label: {
            Image(systemName: "minus.circle.fill")
        }
        .imageScale(.large)
        .foregroundStyle(.red)
        .buttonStyle(.plain)
    }
}

// Amount & GST Fields

private struct AmountField: View {
    @Binding var value: Decimal
    @FocusState var focused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Amount")
            CurrencyField(value: $value)
        }
        .focused($focused)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}

private struct GSTField: View {
    var gstMethod: WSTemplate.GSTMethod
    @Binding var value: Decimal
    @FocusState var focused
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch gstMethod {
            case .notApplicable:
                Text("GST (N/A)")
                CurrencyField(value: $value, disabled: true)
                
            case .tenPercent:
                Text("GST (10%)")
                CurrencyField(value: $value, disabled: true)
                    
            case .input:
                Text("GST")
                CurrencyField(value: $value)
            }
        }
        .focused($focused)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
    }
}

/// Wrapper of `CommonUI.CurrencyField` with styling and disabled flag.
private struct CurrencyField: View {
    @Binding var value: Decimal
    var disabled: Bool = false
    
    var body: some View {
        Group {
            if !disabled {
                CommonUI.CurrencyField("", value: $value)
                    .foregroundStyle(.tint)
                
            } else {
                CommonUI.CurrencyField("", value: $value)
                    .disabled(true)
                    .opacity(0.5)
            }
        }
        .font(.system(size: 22))
    }
}

// Models

@Observable
private class SupplierData {
    let supplier: WSTemplate.Supplier
    
    init(supplier: WSTemplate.Supplier) {
        self.supplier = supplier
    }
    
    var amount: Decimal = 0 {
        didSet {
            if supplier.gstMethod == .tenPercent {
                gst = amount / 11.0
            }
        }
    }
    
    var gst: Decimal = 0
}

@Observable
private class CustomSupplierData {
    var id: String = BSONObjectID().hex
    var name: String = ""
    var amount: Decimal = 0
    var gst: Decimal = 0
}

// Utils

private extension View {
    @ViewBuilder
    func sectionBackground() -> some View {
        modifier(SectionBackgroundModififer())
    }
}

private struct SectionBackgroundModififer: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12)
        
//        if #available(iOS 26, *) {
//            content.glassEffect(.regular, in: shape)
//        } else {
            if colorScheme == .dark {
                content.background(.regularMaterial, in: shape)
            } else {
                content.background(.white, in: shape)
            }
//        }
    }
}

// Preview

#Preview {
    @Previewable @State var template: WSTemplate?
        
    Text("Loading...")
        .fullScreenCover(item: $template) { template in
            NewReportView(template: template, user: WSReport.User(id: "", email: "", name: ""))
        }
        .task {
            do {
                template = try await API.shared.mockTemplate()
            } catch {
                print("Error retrieving template \(error)")
            }
        }
        .tint(Color.theme)
}
