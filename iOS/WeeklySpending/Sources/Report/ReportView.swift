import Foundation
import SwiftUI
import Backend
import CommonUI

struct ReportView: View {
    var template: WSTemplate
    var user: WSReport.User
    @State private var supplierDataMap: [String: SupplierData]
    @State private var customSuppliersData: [CustomSupplierData] = []
    @State private var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    
    init(template: WSTemplate, user: WSReport.User) {
        self.template = template
        self.user = user

        self.supplierDataMap = Dictionary(
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
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(template.sections, id: \.id) { section in
                sectionView(section)
            }
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
                        let supplierData = supplierDataMap[supplier.id]!
                        SupplierView(supplier: supplier, data: supplierData)
                        
                        if row.supplierId != section.rows.last?.supplierId {
                            Divider()
                        }
                        
                    } else {
                        Text("ERROR").foregroundStyle(.red)
                    }
                }
            }
            .glassEffectShim(in: RoundedRectangle(cornerRadius: 12))
        }
    }
        
    private func handleSubmit() {
        Task {
            do {
                ps.presentProgressHUD(title: "Submitting...")
                
                let report = report()
                try await API.shared.post(method: "POST", path: "/submit", body: report)
                
                ps.dismiss()
                
            } catch {
                ps.dismiss()
                ps.presentAlert(error: error)
            }
        }
    }
    
    /// Creates report from view data.
    private func report() -> WSReport {
        WSReport(
            template: template,
            user: user,
            date: Date(),
            suppliersData: template.suppliers.map {
                let data = supplierDataMap[$0.id]!
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
        HStack(alignment: .firstTextBaseline, spacing: 50) {
            Text(supplier.name)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Amount")
                    CurrencyField(value: $data.amount)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    switch supplier.gstMethod {
                    case .notApplicable:
                        Text("GST (N/A)")
                        CurrencyField(value: $data.gst, disabled: true)
                        
                    case .tenPercent:
                        Text("GST (10%)")
                        CurrencyField(value: $data.gst, disabled: true)
                            
                    case .input:
                        Text("GST")
                        CurrencyField(value: $data.gst)
                    }
                    
                }
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
                VStack(alignment: .leading, spacing: 3) {
                    Text("Amount")
                    CurrencyField(value: $data.amount)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    switch supplier.gstMethod {
                    case .notApplicable:
                        Text("GST (N/A)")
                        CurrencyField(value: $data.gst, disabled: true)
                        
                    case .tenPercent:
                        Text("GST (10%)")
                        CurrencyField(value: $data.gst, disabled: true)
                            
                    case .input:
                        Text("GST")
                        CurrencyField(value: $data.gst)
                    }
                    
                }
            }
        }
        .padding()
    }
}

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
        .currencyFieldFont()
    }
}

private extension View {
    @ViewBuilder
    func currencyFieldFont() -> some View {
        self.font(.system(size: 22))
    }
}

@Observable
private class ReportViewModel {
    var supplierDataMap: [String: SupplierData] = [:]
    
//    init(for template: Template) {
//        
//    }
    
    
}

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
    var name: String = ""
    var amount: Decimal = 0
    var gst: Decimal = 0
}

#Preview {
    @Previewable @State var template: WSTemplate?
        
    Text("Loading...")
        .fullScreenCover(item: $template) { template in
            ReportView(template: template, user: WSReport.User(id: "", email: "", name: ""))
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
