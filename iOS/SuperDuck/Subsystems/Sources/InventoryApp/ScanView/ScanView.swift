import Foundation
import SwiftUI
import AVFoundation
import Common
import CommonUI

/// View that displays camera, barcode info and Finish button.
struct ScanView: View {
    var store: Store
    var mode: Mode
    @State var detectedBarcodes: [String] = []
    @State var scanRecords: [ScanRecord] = []
    @State var presentingFinishedView = false
    @State var presentingReviewView = false
    @State var presentingConfirmCancel = false
    @State var didSubmitResult = false
    @State var soundPlayer: AVAudioPlayer
    @State var ps = PresentationState()
    @State var rectOfInterest: CGRect = .zero
    @Environment(\.dismiss) private var dismiss
    @Environment(InventoryApp.Defaults.self) private var defaults
    
    init(store: Store, mode: Mode) {
        self.store = store
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
                // Try DispatchQueue.main.async here if it doesn't work
                // Did not work at some point without async
                rectOfInterest = rect
            }
        )
        .overlay(alignment: .top) {
            if rectOfInterest != .zero {
                // VStack laid out in a way that it is just below the rect of interest and line up with it
                
                VStack(spacing: 16) {
                    controlsView()
                    debugInputButton()
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
                if scanRecords.count > 0 {
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
            
            Text("Items: \(scanRecords.count)")
                .bold()
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .modified {
                    if #available(iOS 26, *) {
                        $0.glassEffect(.clear)
                    } else {
                        $0
                    }
                }
            
            Spacer()

            // Review button
            
            Button("Review") {
                ps.presentSheet {
                    ReviewView(
                        store: store,
                        scanMode: mode,
                        scanRecords: scanRecords,
                        onSubmitted: {
                            dismiss()
                        }
                    )
                }
            }
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
            .disabled(scanRecords.isEmpty)
        }
    }
    
    @ViewBuilder
    private func debugInputButton() -> some View {
        Button("[Debug] Show input alert") {
            let items: [Store.Item] = [
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
        .modified {
            if #available(iOS 26, *) {
                $0.buttonSizing(.flexible)
            } else {
                $0
            }
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

extension ScanView {
    enum Mode {
        case add
        case remove
    }
}

#Preview {
    ScanView(
        store: .init(
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
