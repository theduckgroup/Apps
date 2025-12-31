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
    @State var rectOfInterest: CGRect = .zero
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
    }
    
    var body: some View {
        content()
            .presentations(ps)
    }
    
    @ViewBuilder
    private func content() -> some View {
        BarcodeScanner(
            minPresenceTime: defaults.scanner.minPresenceTime,
            minAbsenceTime: defaults.scanner.minAbsenceTime,
            detectionEnabled: !presentingFinishedView && !didSubmitResult,
            detectedBarcodes: $detectedBarcodes,
            persistentBarcodeHandler: { barcode in
                handleBarcodeDetected(barcode)
            },
            onRectOfInterestChange: { rect in
                // DispatchQueue.main.async {
                rectOfInterest = rect
                // }
            }
        )
        .overlay(alignment: .top) {
            if rectOfInterest != .zero {
                // VStack laid out in a way that it is just below the rect of interest and line up with it
                
                VStack(spacing: 0) {
                    controlsView()
                    
                    if #available(iOS 26, *) {
                        debugInputButton()
                            .padding(.top, 16)
                    }
                }
                .padding(.top, rectOfInterest.maxY)
                .padding(.top, 16)
                .padding(.horizontal, rectOfInterest.minX)
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func controlsView() -> some View {
        HStack {
            // Cancel button
            
            Button {
                if scannedItems.count > 0 {
                    ps.presentAlert(title: "Cancel scanning?", message: "Scanned items will be lost.") {
                        Button("Continue Scanning", role: .cancel) {}

                        Button("Cancel Scanning", role: .destructive) {
                            dismiss()
                        }
                    }
                    
                } else {
                    dismiss()
                }
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.bordered)

            Spacer()

            // Scanned items label
            
            Text("Items: \(scannedItems.count)")
                .bold()
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .modified {
                    if #available(iOS 26, *) {
                        $0.glassEffect(.clear)
                    }
                }
            
            Spacer()

            // Review button
            
            Button("Review") {
                ps.presentSheet {
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
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
            .disabled(scannedItems.isEmpty)
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private func debugInputButton() -> some View {
        Button("Show debug input alert") {
            let items: [Vendor.Item] = [
                .init(id: "0", name: "Herbal Jelly Clone", code: "AX007"),
                .init(id: "1", name: "Water Bottle", code: "BD020"),
                .init(id: "2", name: "Chicken Powder", code: "CP009"),
                .init(id: "3", name: "Commodo nisi aliquip", code: "CNAL5453"),
                .init(id: "4", name: "Eiusmod proident esse aliqua", code: "BLXZ"),
                .init(id: "5", name: "Aliqua do irure proident", code: "AD0012"),
                .init(id: "6", name: "Enim mollit voluptate", code: "EMV002"),
            ]
            
            let item = items.randomElement()!
            presentQuantityInputAlert(for: item)
        }
        .buttonSizing(.flexible)
        .buttonStyle(.glass)
    }
    
    private func handleBarcodeDetected(_ barcode: String) {
        let item = vendor.catalog.items.first { $0.code == barcode }
        
        guard let item else {
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        
        presentQuantityInputAlert(for: item)
    }
    
    private func presentQuantityInputAlert(for item: Vendor.Item) {
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
