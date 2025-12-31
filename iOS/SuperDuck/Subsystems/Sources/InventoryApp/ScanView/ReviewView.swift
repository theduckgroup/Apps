import Foundation
import SwiftUI
import Common

struct ReviewView: View {
    var store: Store
    var scanMode: ScanView.Mode
    var scanRecords: [ScanRecord]
    var onSubmitted: () -> Void = {}
    @State var submitting = false
    @State var presentedError: String?
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
                ForEach(scanRecords.grouped(), id: \.storeItem.id) { group in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text(group.storeItem.name)
                            Text(group.storeItem.code)
                        }

                        Spacer()

                        Text("\(group.totalQuantity)")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 9)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                }
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
            changes: scanRecords.grouped().map {
                .init(itemId: $0.storeItem.id, inc: $0.totalQuantity * factor)
            }
        )

        let path = "/api/store/\(store.id)/catalog"
        // var request = try await InventoryServer.makeRequest(httpMethod: "POST", path: path)
        // request.httpBody = try! JSONEncoder().encode(body)
        
        // _ = try await HTTPClient.shared.post(request, json: true)
    }
}

#Preview {
    NavigationStack {
        ReviewView(
            store: .mock,
            scanMode: .add,
            scanRecords: [
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 5),
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 3),
                .init(storeItem: .init(id: "rock-salt", name: "Rock Salt", code: "RKST"), quantity: 2),
                .init(storeItem: .init(id: "water-bottle", name: "Water Bottle", code: "WTBLT"), quantity: 1),
                .init(storeItem: .init(id: "rock-salt", name: "Rock Salt", code: "RKST"), quantity: 4),
            ]
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Scanned Items")
    }
    .preferredColorScheme(.dark)
}
