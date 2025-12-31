import Foundation
import SwiftUI
import AVFoundation
import Common
import CommonUI

/// View that displays camera, barcode info and Finish button.
struct ScanView: View {
    var vendor: Vendor
    var mode: Mode
    @State var detectedBarcodes: [String] = []
    @State var scannedItems: [ScannedItem] = []
    @State var presentingFinishedView = false
    @State var presentingReviewView = false
    @State var presentingConfirmCancel = false
    @State var didSubmitResult = false
    @State var soundPlayer: AVAudioPlayer
    @State var ps = PresentationState()
    @Environment(\.dismiss) private var dismiss
    @Environment(InventoryApp.Defaults.self) private var defaults
    
    init(vendor: Vendor, mode: Mode) {
        self.vendor = vendor
        self.mode = mode

        self.soundPlayer = {
            let bundleResourcesURL = Bundle.module.url(forResource: "Resources", withExtension: "bundle")!
            let url = bundleResourcesURL.appending(path: "ScanSound.aiff")
            return try! AVAudioPlayer(contentsOf: url)
        }()
        
        if isRunningForPreviews {
            _detectedBarcodes = .init(wrappedValue: ["WTBTL"])
            _scannedItems = .init(wrappedValue: [.init(itemID: "water-bottle", code: "WTBLT", name: "Water Bottle")])
        }
    }
    
    var body: some View {
        content()
            .presentations(ps)
            .sheet(isPresented: $presentingReviewView) {
                ReviewView(
                    vendor: vendor,
                    scannedItems: scannedItems,
                    scanMode: mode,
                    finished: false
                )
            }
            .sheet(isPresented: $presentingFinishedView) {
                ReviewView(
                    vendor: vendor,
                    scannedItems: scannedItems,
                    scanMode: mode,
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
            ZStack(alignment: .top) {
                BarcodeScanner(
                    minPresenceTime: defaults.scanner.minPresenceTime,
                    minAbsenceTime: defaults.scanner.minAbsenceTime,
                    detectionEnabled: !presentingFinishedView && !didSubmitResult,
                    detectedBarcodes: $detectedBarcodes
                ) { barcode in
                    handleBarcodeDetected(barcode)
                }

                // Controls aligned with cutout rectangle
                let safeInsets = geometryProxy.safeAreaInsets
                let padding: CGFloat = 24
                let availableHeight = geometryProxy.size.height - safeInsets.top - padding - safeInsets.bottom - padding
                let cutoutHeight = availableHeight / 2
                let controlsTopOffset = safeInsets.top + padding + cutoutHeight + 16

                controlsView()
                    .font(.callout)
                    .padding(.horizontal, safeInsets.leading + padding)
                    .offset(y: controlsTopOffset)
            }
            .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private func controlsView() -> some View {
        HStack(spacing: 16) {
            // Cancel button
            Button {
                if scannedItems.count > 0 {
                    presentingConfirmCancel = true
                } else {
                    dismiss()
                }
            } label: {
                Text("Cancel")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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

            Spacer()

            // Scanned items label
            if scannedItems.count > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(scannedItems.count) \(scannedItems.count > 1 ? "items" : "item") scanned")
                    Image(systemName: "info.circle.fill")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    presentingReviewView = true
                }
            }

            // Finish button
            Button("Finish") {
                presentingFinishedView = true
            }
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
        }
    }
    
    
    private func handleBarcodeDetected(_ barcode: String) {
        let item = vendor.catalog.items.first { $0.code == barcode }
        
        guard let item else {
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        
        ps.presentAlertStyleCover(offset: .init(x: 0, y: -42)) {
            QuantityInputAlert(
                title: item.name,
                subtitle: item.code,
                onCancel: {
                    ps.dismiss()
                },
                onDone: { value in
                    ps.dismiss()
                    scannedItems.append(.init(itemID: item.id, code: item.code, name: item.name))
                }
            )
        }
        
        // scannedItems.append(.init(itemID: item.id, code: item.code, name: item.name))
    }
    
    private func handleFinish() {
        presentingFinishedView = true
    }
}

extension ScanView {
    enum Mode {
        case add
        case subtract
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
        mode: .add
    )
    .previewEnvironment()
}
