import Foundation
import SwiftUI
import AVFoundation
import Backend
import Common
import CommonUI

/// View that displays camera, barcode info and Finish button.
struct ScanView: View {
    var store: Store
    var scanMode: ScanMode
    @State var detectedBarcodes: [String] = []
    @State var scanRecords: [ScanRecord] = []
    @State var presentingFinishedView = false
    @State var presentingReviewView = false
    @State var presentingConfirmCancel = false
    @State var didSubmitResult = false
    @State var soundPlayer: AVAudioPlayer
    @State var rectOfInterest: CGRect?
    @State var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    @Environment(InventoryAppDefaults.self) private var defaults
    
    init(store: Store, scanMode: ScanMode) {
        self.store = store
        self.scanMode = scanMode

        self.soundPlayer = {
            let bundleResourcesURL = Bundle.module.url(forResource: "Resources", withExtension: "bundle")!
            let url = bundleResourcesURL.appending(path: "ScanSound.aiff")
            return try! AVAudioPlayer(contentsOf: url)
        }()
    }
    
    var body: some View {
        NavigationStack {
            bodyContent()
                .toolbar { toolbarContent() }
                .navigationTitle(scanMode == .add ? "Add Items" : "Remove Items")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $presentingReviewView) {
                    ReviewView(store: store, scanMode: scanMode, scanRecords: scanRecords, onSubmitted: { dismiss() })
                }
                .presentations(ps)
                .ignoresSafeArea()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.automatic)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Review") {
                // There is a bug here:
                // - Comment out the code below to use ps
                // - Change submit route to trigger an error
                // - In Review screen, submit
                // - The error alert flashes and auto-dismisses
                
//                ps.presentSheet {
//                    ReviewView(
//                        store: store,
//                        scanMode: scanMode,
//                        scanRecords: scanRecords,
//                        onSubmitted: {
//                            dismiss()
//                        }
//                    )
//                }
                presentingReviewView = true
            }
            .modified {
                if #available(iOS 26, *) {
                    $0.buttonStyle(.glassProminent)
                } else {
                    $0.buttonStyle(.borderedProminent)
                }
            }
            .disabled(scanRecords.isEmpty)
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        BarcodeScanner(
            minPresenceTime: defaults.scanner.minPresenceTime,
            minAbsenceTime: defaults.scanner.minAbsenceTime,
            detectionEnabled: !presentingFinishedView && !didSubmitResult,
            detectedBarcodes: $detectedBarcodes,
            persistentBarcodeHandler: { barcode in
                handleBarcodeDetected(barcode)
            },
            onRectOfInterestChange: { rect in
                // Try DispatchQueue.main.async here if it doesn't work
                // Did not work at some point without it
                rectOfInterest = rect
            }
        )
        .overlay(alignment: .top) {
            if let rectOfInterest {
                // VStack laid out in a way that it is just below the rect of interest and line up with it
                
                VStack(spacing: 16) {
                    quantityLabel()
                    debugAddItemButton()
                }
                .padding(.top, rectOfInterest.maxY)
                .padding(.top, 16)
                .padding(.horizontal, rectOfInterest.minX)
            }
        }
    }
    
    @ViewBuilder
    private func quantityLabel() -> some View {
        let quantity = scanRecords.map(\.quantity).sum()
        
        if quantity > 0 {
            Text("\(quantity) \("Item".pluralized(count: quantity)) selected")
                .font(.title3.smallCaps().monospacedDigit())
                .multilineTextAlignment(.center)
        } else {
            Text("Scan QR Code")
                .font(.title3)
        }
    }
    
    @ViewBuilder
    private func debugAddItemButton() -> some View {
        Button("[Debug] Add Item") {
            let item = store.catalog.items.randomElement()!
            presentQuantityInputAlert(for: item)
        }
        .buttonStyle(.bordered)
    }
    
    private func handleBarcodeDetected(_ barcode: String) {
        let item = store.catalog.items.first { $0.code == barcode }

        guard let item else {
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        
        presentQuantityInputAlert(for: item)
    }
    
    private func presentQuantityInputAlert(for item: Store.Item) {
        ps.presentAlertStyleCover(offset: .init(x: 0, y: -42)) {
            QuantityInputAlert(
                title: item.name,
                subtitle: item.code,
                onCancel: {
                    ps.dismiss()
                },
                onDone: { quantity in
                    ps.dismiss()
                    scanRecords.append(.init(storeItem: item, quantity: quantity))
                }
            )
        }
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
                    
                    ps.presentFullScreenCover {
                        ScanView(store: store, scanMode: .add)
                    }
                }
            }
        }
    }
    
    return PreviewView()
        .previewEnvironment()
}
