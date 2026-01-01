import Foundation
import SwiftUI
import Common
import CommonUI
import Backend

struct PastReportView: View {
    var reportMeta: WSReportMeta
    @State var report: WSReport?
    @State var error: Error?
    @State var isFetching = false
    @State var containerSize: CGSize?
    @Environment(API.self) var api
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ScrollView(.vertical) {
            let containerSize = containerSize ?? .zero
            
            let needsReadablePadding = (
                horizontalSizeClass == .regular && verticalSizeClass == .regular &&
                containerSize.width > containerSize.height * 1.25
            )
            
            contentView()
                .padding()
                .frame(maxWidth: needsReadablePadding ? containerSize.width * 0.66 : nil, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center) // Scroll indicator is messed up without this
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Infinite layout loop without this
        .readSize(assignTo: $containerSize)
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
            
            if let report {
                tableView(report)
                
            } else if let error {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .padding(.top, 18) // Match table view header
                
            } else if isFetching {
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
                        .gridCellColumns(index == 0 ? 1 : 3)
                    
                    if index == 0 {
                        Text("Amount")
                            .bold()
                            .gridColumnAlignment(.trailing)
                        
                        Text("GST")
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
                                
                            Text(supplierData.amount, format: .currency(code: "AUD"))
                                .gridColumnAlignment(.trailing)
                                .foregroundStyle(.secondary)
                            
                            Text(supplierData.gst, format: .currency(code: "AUD"))
                                .gridColumnAlignment(.trailing)
                                .foregroundStyle(.secondary)
                            
                        } else {
                            Text("Supplier not found")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 12)
                    
                    Divider()
                }
            }
        }
    }
    
    private func fetchReport() {
        Task {
            do {
                isFetching = true
                
                defer {
                    isFetching = false
                }
                
                let report = try await api.report(id: reportMeta.id)
                
                self.report = report
                
            } catch {
                self.error = error
            }
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
    NavigationStack {
        PastReportView(
            reportMeta: .init(
                id: "693b8fb1941f7b76e094c7bd", // From Mongo DB
                template: .mock,
                user: .mock,
                date: Date()
            )
        )
    }
}
