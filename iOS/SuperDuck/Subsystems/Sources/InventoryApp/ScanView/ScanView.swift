import Foundation
import SwiftUI
import AVFoundation
import Backend
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
    @State var rectOfInterest: CGRect?
    @State var ps = PresentationState()
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
                    controlsView()
                    debugInputButton()
                }
                .padding(.top, rectOfInterest.maxY)
                .padding(.top, 16)
                .padding(.horizontal, rectOfInterest.minX)
            }
        }
        .presentations(ps)
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
            
            let quantity = scanRecords.map(\.quantity).sum()
            
            Text("\(quantity) Items")
                .font(.body.weight(.semibold).smallCaps().monospacedDigit())
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
            .buttonStyle(.borderedProminent)
            .disabled(scanRecords.isEmpty)
        }
    }
    
    @ViewBuilder
    private func debugInputButton() -> some View {
        Button("[Debug] Show input alert") {
            let item = store.catalog.items.randomElement()!
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
                        ScanView(store: store, mode: .add)
                    }
                }
            }
        }
    }
    
    return PreviewView()
        .previewEnvironment()
}
