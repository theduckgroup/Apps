import Foundation
import SwiftUI
import AVFoundation
import Common
import CommonUI

/// View that displays camera, barcode info and Finish button.
struct ScanView: View {
    var vendor: Vendor
    var scanMode: ScanMode
    @State var detectedBarcodes: [String] = []
    @State var scannedItems: [ScannedItem] = []
    @State var presentingFinishedView = false
    @State var presentingReviewView = false
    @State var presentingConfirmCancel = false
    @State var didSubmitResult = false
    @State var soundPlayer = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "The_sample_workshop__2690_vial_tap_br-f5-tmc", withExtension: "aiff")!)
    @Environment(\.dismiss) private var dismiss
    // @Environment(AppDefaults.self) private var appDefaults
    // let store = InventoryStore.shared
    
    init(vendor: Vendor, scanMode: ScanMode) {
        self.vendor = vendor
        self.scanMode = scanMode
        
        if isRunningForPreviews {
            _detectedBarcodes = .init(wrappedValue: ["WTBTL"])
            _scannedItems = .init(wrappedValue: [.init(itemID: "water-bottle", code: "WTBLT", name: "Water Bottle")])
        }
    }
    
    var body: some View {
        content()
            .sheet(isPresented: $presentingReviewView) {
                ReviewView(
                    vendor: vendor,
                    scannedItems: scannedItems,
                    scanMode: scanMode,
                    finished: false
                )
            }
            .sheet(isPresented: $presentingFinishedView) {
                ReviewView(
                    vendor: vendor,
                    scannedItems: scannedItems,
                    scanMode: scanMode,
                    finished: true,
                    onSubmitted: {
                        dismiss()
                    }
                )
            }
    }
    
    @ViewBuilder
    private func content() -> some View {
        GeometryReader { geometryProxy in
            ZStack(alignment: .center) {
                BarcodeScanner(
                    minPresenceTime: 0.250, // appDefaults.scanner.minPresenceTime,
                    minAbsenceTime: 0.500, // appDefaults.scanner.minAbsenceTime,
                    detectionEnabled: !presentingFinishedView && !didSubmitResult,
                    detectedBarcodes: $detectedBarcodes
                ) { barcode in
                    print("Persistent barcode: \(barcode)")
                    
                    handleBarcode(barcode)
                }
                
                VStack {
                    if scannedItems.count > 0 {
                        scannedItemsLabel()
                            .padding(.top, max(geometryProxy.safeAreaInsets.top, 54) + 30)
                    }
                    
                    Spacer()
                    
                    barcodesInfo()
                        .padding(.horizontal, 36)
                        .multilineTextAlignment(.center)
                    
                    bottomButtons()
                        .padding(.bottom, max(geometryProxy.safeAreaInsets.bottom, 42))
                }
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func scannedItemsLabel() -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(scannedItems.count) \(scannedItems.count > 1 ? "items" : "item") scanned")
            
            Image(systemName: "info.circle.fill")
                // .foregroundStyle(.accent)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            presentingReviewView = true
        }
    }
    
    @ViewBuilder
    private func barcodesInfo() -> some View {
        Group {
            switch detectedBarcodes.count {
            case 0:
                EmptyView()
                
            case 1:
                let barcode = detectedBarcodes[0]
                let item = vendor.catalog.items.first { $0.code == barcode }
                
                if let item {
                    VStack {
                        Text(item.name)
                            .foregroundStyle(Color.black)
                        
                        Text(barcode)
                            .foregroundStyle(Color.black)
                    }
                    
                } else {
                    VStack {
                        Text("Invalid code (\(barcode))")
                            .foregroundStyle(Color.red)
                        
//                        Text(barcodes[0])
//                            .foregroundStyle(Color.black)
                    }
                }
                
            default:
                Text("Multiple codes detected")
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 3)
        .frame(minWidth: 210)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.yellow)
        }
    }
    
    @ViewBuilder
    private func bottomButtons() -> some View {
        HStack(spacing: 36) {
            Button {
                if scannedItems.count > 0 {
                    presentingConfirmCancel = true
                    
                } else {
                    dismiss()
                }
                
            } label: {
                Text("Cancel")
                    .padding(.vertical)
                    .contentShape(Rectangle())
            }
            .alert(
                "Confirm",
                isPresented: $presentingConfirmCancel,
                actions: {
                    Button("Stop Scanning", role: .destructive) {
                        dismiss()
                    }
                    
                    Button("Continue Scanning", role: .cancel) {}
                },
                message: {
                    Text("Cancel scanning? Progress will be lost.")
                }
            )
            
            Button("Finish") {
                presentingFinishedView = true
            }
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
        }
        .font(.title3)
        .padding(.horizontal, 24)
        .padding(.vertical)
    }
    
    private func handleBarcode(_ barcode: String) {
        let item = vendor.catalog.items.first { $0.code == barcode }
        
        guard let item else {
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        
        scannedItems.append(.init(itemID: item.id, code: item.code, name: item.name))
    }
    
    private func handleFinish() {
        presentingFinishedView = true
    }
}

private struct ReviewView: View {
    var vendor: Vendor
    var scannedItems: [ScannedItem]
    var scanMode: ScanMode
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

#Preview {
    ScanView(
        vendor: .init(
            id: "0",
            name: "ND Central Kitchen",
            catalog: .init(
                items: [
                    .init(
                        id: "water-bottle",
                        name: "Water Bottle",
                        code: "WTBTL"
                    ),
                    .init(
                        id: "rock-salt",
                        name: "Rock Salt",
                        code: "RKST"
                    )
                ],
                sections: []
            )
        ),
        scanMode: .add
    )
    // .environment(AppDefaults.shared)
}
