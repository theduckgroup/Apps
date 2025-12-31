import Foundation
import SwiftUI
import Common

struct ReviewView: View {
    var vendor: Vendor
    var scannedItems: [ScannedItem]
    var scanMode: ScanView.Mode
    var finished: Bool
    var onSubmitted: () -> Void = {}
    @State var submitting = false
    @State var presentedError: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScannedItemListView(scannedItems: scannedItems)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Scanned Items (\(scannedItems.count))")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(submitting)
                    }
                    
                    if finished {
                        ToolbarItem(placement: .topBarTrailing) {
                            if !submitting {
                                Button("Submit") {
                                    submit()
                                }
                                .fontWeight(.bold)
                                
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                }
        }
        .alert(
            "Error",
            presenting: $presentedError,
            actions: { _ in
                Button("OK") {}
            },
            message: {
                Text($0)
            }
        )
    }
    
    private func submit() {
        Task {
            submitting = true
            
            defer {
                submitting = false
            }
            
            do {
                try await submitImpl()
                onSubmitted()
                
            } catch {
                presentedError = formatError(error)
            }
        }
    }
    
    private func submitImpl() async throws {
        struct Body: Encodable {
            var vendorId: String
            var changes: [Change]
            
            struct Change: Encodable {
                var itemId: String
                var inc: Int
            }
        }
        
        let factor = scanMode == .add ? 1 : -1
        
        let body = Body(
            vendorId: vendor.id,
            changes: scannedItems.grouped().map {
                .init(itemId: $0.item.itemID, inc: $0.count * factor)
            }
        )
        
        let path = "/api/vendor/\(vendor.id)/item-quantities"
        // var request = try await InventoryServer.makeRequest(httpMethod: "POST", path: path)
        // request.httpBody = try! JSONEncoder().encode(body)
        
        // _ = try await HTTPClient.shared.post(request, json: true)
    }
}
