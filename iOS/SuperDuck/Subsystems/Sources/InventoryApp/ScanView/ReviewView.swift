import Foundation
import SwiftUI
import Backend
import Common
import CommonUI

struct ReviewView: View {
    var store: Store
    var mode: ScanView.Mode
    var scanRecords: [ScanRecord]
    var onSubmitted: () -> Void = {}
    @State var submitting = false
    @State var ps = PresentationState()
    @Environment(API.self) var api
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            listView()
                .navigationTitle("Items")
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
            .fixedSize()
            .buttonStyle(.automatic)
            .disabled(submitting)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            if !submitting {
                Button("Submit") {
                    submit()
                }
                .modified {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glassProminent)
                    } else {
                        $0.buttonStyle(.borderedProminent)
                    }
                }
                
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
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
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Total")
                        .bold()
                    
                    Spacer()
                    
                    Text("\(totalQuantity)")
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
    
    private func submit() {
        Task {
            submitting = true
            defer { submitting = false }
            
            do {
                try await api.submit(store, mode, scanRecords)
                onSubmitted()
                
            } catch {
                ps.presentAlert(error: error)
            }
        }
    }
}

private extension API {
    func submit(_ store: Store, _ mode: ScanView.Mode, _ scanRecords: [ScanRecord]) async throws {
        if isRunningForPreviews {
            try await Task.sleep(for: .seconds(1))
            // throw GenericError("Anim deserunt do eiusmod cupidatat.")
            return
        }

        struct Body: Encodable {
            var changes: [Change]
            
            struct Change: Encodable {
                var itemId: String
                var inc: Int
            }
        }
        
        let factor = mode == .add ? 1 : -1

        let body = Body(
            changes: scanRecords.map {
                .init(itemId: $0.storeItem.id, inc: $0.quantity * factor)
            }
        )

        let path = "/api/store/\(store.id)/catalog"
        
        try await post(method: "POST", path: path, body: body)
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
                            mode: .add,
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
