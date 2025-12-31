import Foundation
import SwiftUI
import Backend
import Common
import CommonUI

struct ReviewView: View {
    var store: Store
    var scanMode: ScanView.Mode
    var scanRecords: [ScanRecord]
    var onSubmitted: () -> Void = {}
    @State var submitting = false
    @State var presentedError: String?
    @Environment(API.self) var api
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            listView()
                .navigationTitle("Review")
                .toolbar { toolbarContent() }
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
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .disabled(submitting)
        }
        
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
    
    @ViewBuilder
    private func listView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let sortedScanRecords = scanRecords.localizedStandardSorted(on: \.storeItem.name)
                
                ForEach(Array(sortedScanRecords.enumerated()), id: \.offset) { _, record in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text(record.storeItem.name)
                            Text(record.storeItem.code).foregroundStyle(.secondary)
                        }
                        
                        Spacer()

                        Text("\(record.quantity)").foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        Divider().padding(.leading)
                    }
                }
                
                let totalQuantity = scanRecords.map(\.quantity).sum()
                Text("Total: \(totalQuantity)").foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
            }
        }
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
            vendorId: store.id,
            changes: scanRecords.map {
                .init(itemId: $0.storeItem.id, inc: $0.quantity * factor)
            }
        )

        let path = "/api/store/\(store.id)/catalog"

        try await api.submit(store, scanRecords)
        // var request = try await InventoryServer.makeRequest(httpMethod: "POST", path: path)
        // request.httpBody = try! JSONEncoder().encode(body)
        
        // _ = try await HTTPClient.shared.post(request, json: true)
    }
}

#Preview {
    struct PreviewView: View {
        @State var ps = PresentationState()
        @Environment(API.self) var api
        
        var body: some View {
            ZStack {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
                    .controlSize(.large)
            }
            .presentations(ps)
            .onFirstAppear {
                Task {
                    let store = try await api.store()
                    
                    let scanRecords = (0..<10).map { _ in
                        let storeItem = store.catalog.items.randomElement()!
                        let quantity = Int.random(in: 1...20)
                        return ScanRecord(storeItem: storeItem, quantity: quantity)
                    }
                    
                    ps.presentSheet {
                        ReviewView(
                            store: store,
                            scanMode: .add,
                            scanRecords: scanRecords
                        )
                    }
                }
            }
        }
    }
    
    return PreviewView()
        .previewEnvironment()
}
