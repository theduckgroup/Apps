import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct ReportView: View {
    var reportMeta: WSReportMeta
    @State var reportFetcher = ValueFetcher<WSReport>()
    @State var containerSize: CGSize?
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView(.vertical) {
            contentView()
                .padding()
        }
        .navigationTitle("Spending")
        .onFirstAppear {
            fetchReport()
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView()
                .padding(.bottom, 18)
            
            if let report = reportFetcher.value {
                tableView(report)
                
            } else if let error = reportFetcher.error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 18) // Match table view header
                
            } else if reportFetcher.isFetching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.secondary)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 18) // Match table view header
            }
        }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 0) {
            GridRow(alignment: .firstTextBaseline) {
                Text("Store")
                    .bold()
                
                Text(reportMeta.user.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            
            Divider()
            
            GridRow(alignment: .firstTextBaseline) {
                Text("Date")
                    .bold()
                
                Text(reportMeta.date.formatted(.dateTime.weekday(.wide).day().month().year().hour().minute()))
            }
            .padding(.vertical, 12)
            
            Divider()
        }
    }
    
    @ViewBuilder
    private func tableView(_ report: WSReport) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 0) {
            ForEach(Array(report.template.sections.enumerated()), id: \.offset) { index, section in
                // Header
            
                GridRow(alignment: .firstTextBaseline) {
                    Text(section.name)
                        .bold()
                        .gridCellColumns(index == 0 ? 1 : 4)
                    
                    if index == 0 {
                        Text("Amount")
                            .bold()
                            .gridColumnAlignment(.trailing)
                        
                        Text("GST")
                            .bold()
                            .gridColumnAlignment(.trailing)
                        
                        Text("Credit")
                            .bold()
                            .gridColumnAlignment(.trailing)
                    }

                }
                .padding(.top, 18)
                .padding(.bottom, 9)
                
                Divider()
                
                // Rows
                
                ForEach(Array(section.rows.enumerated()), id: \.offset) { index, row in
                    GridRow(alignment: .firstTextBaseline) {
                        let supplier = report.template.suppliers.first { $0.id == row.supplierId }
                        let supplierData = report.suppliersData.first { $0.supplierId == row.supplierId }
                        
                        if let supplier, let supplierData {
                            Text(supplier.name)
                               
                            Group {
                                Text(formatAmount(supplierData.amount))
                                Text(formatAmount(supplierData.gst))
                                Text(formatAmount(supplierData.credit))
                            }
                            .gridColumnAlignment(.trailing)
                            .foregroundStyle(.secondary)

                        } else {
                            Text("Supplier not found")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            
            
            
            // Total section
            
            GridRow(alignment: .firstTextBaseline) {
                Text("Total")
                   
                Group {
                    Text("Amount")
                    Text("GST")
                    Text("Credit")
                }
                .gridColumnAlignment(.trailing)
            }
            .bold()
            .padding(.top, 18)
            .padding(.bottom, 9)
            
            Divider()
            
            GridRow(alignment: .firstTextBaseline) {
                Text("")
                
                let totalAmount = report.suppliersData.map(\.amount).sum() + report.customSuppliersData.map(\.amount).sum()
                let totalGST = report.suppliersData.map(\.gst).sum() + report.customSuppliersData.map(\.gst).sum()
                let totalCredit = report.suppliersData.map(\.credit).sum() + report.customSuppliersData.map(\.credit).sum()
               
                Group {
                    Text(formatAmount(totalAmount))
                    Text(formatAmount(totalGST))
                    Text(formatAmount(totalCredit))
                }
                .gridColumnAlignment(.trailing)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        if amount == 0 {
            amount.formatted(.currency(code: "AUD").precision(.fractionLength(0)))
        } else {
            amount.formatted(.currency(code: "AUD"))
        }
    }
    
    private func fetchReport() {
        reportFetcher.fetch {
            try await api.report(id: reportMeta.id)
        }
    }
}

struct ReadableContentGuideModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            content
        } else {
            content
        }
    }
}

extension View {
    func readableContentGuide() -> some View {
        modifier(ReadableContentGuideModifier())
    }
}

#Preview {
    PreviewView()
        .previewEnvironment()
}

private struct PreviewView: View {
    @State var reportMeta: WSReportMeta?
    @Environment(API.self) var api
    
    var body: some View {
        NavigationStack {
            if let reportMeta {
                ReportView(reportMeta: reportMeta)
                
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(.secondary)
            }
        }
        .onAppear {
            Task {
                do {
                    let response = try await api.userReportMetas(userID: User.mock.idString)
                    reportMeta = response.data[0]

                } catch {
                    logger.error("Unable to fetch data: \(error)")
                }
            }
        }
    }
}
